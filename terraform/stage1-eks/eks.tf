####################################
# EKS Cluster
####################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = "1.33"
  region             = var.region
  iam_role_name      = var.cluster_iam_role_name

  # EKS Addons
  addons = {
    coredns = {}

    # new pods can assume IAM roles immediately
    eks-pod-identity-agent = {
      before_compute = true # The addon is installed before managed node groups are created.
      # some addons must exist before nodes join the cluster, otherwise node bootstrap may break
    }

    kube-proxy = {}
    vpc-cni = {
      before_compute = true # The addon is installed before managed node groups are created.
    }

  }

  # Basic cluster settings
  vpc_id = module.vpc.vpc_id
  # subnets to place the control plane endpoints
  subnet_ids = module.vpc.private_subnets # required, the control plane needs to know where 
  # the nodes are supposed to exist, 
  # and where to attach internal resources like ENIs.
  # also ensures the correct OIDC provider
  # and networking rules are configured.

  # Enable public endpoint (accessible from local laptop)
  endpoint_public_access = true
  # Enable private endpoint (woker nodes can access via private IP w/ VPC-internal DNS)
  endpoint_private_access = true
  # Restrict to laptop IP
  endpoint_public_access_cidrs = [
    var.my_ip_cidr # Replace this with your real IP
  ]

  # IAM roles for service accounts
  # create OIDC provider for the EKS cluster
  # Without IRSA, your pods cannot securely assume IAM roles. (e.g Load Balancer Controller, EBS CSI driver)
  enable_irsa = true

  ###########################################
  # Managed Node Groups
  ###########################################

  eks_managed_node_groups = {

    ###########################################
    # 1. Core Node Group - Airbyte Core Pods
    ###########################################
    # Runs: airbyte-server, airbyte-worker, airbyte-webapp, airbyte-temporal
    core_nodes = {
      name           = "${var.name_prefix}-core-nodes"
      ami_type       = "AL2023_ARM_64_STANDARD" # ARM (AWS Graviton) is usally cheaper than x86 (Intel/AMD)
      instance_types = ["t4g.large"]            # 2 vCPU, 8 GiB RAM (ARM, Cheaper than t3.large, same spec)
      disk_size      = 20
      capacity_type  = "SPOT" # better use ON_DEMAND. Airbyte core is critical. Spot instances may get interrupted.
      key_name       = var.ec2_key_name

      # auto scaling group
      min_size     = 1
      max_size     = 1
      desired_size = 1 # https://github.com/bryantbiggs/eks-desired-size-hack

      # required, indicate where the node group are deployed 
      subnet_ids = module.vpc.private_subnets

      iam_instance_profile_arn = module.node_group_role.iam_instance_profile_arn

      labels = {
        "airbyte_node_type" = "core" # Assign Airbyte core pods
      }

      tags = {
        "Name" = "${var.name_prefix}-private-core-nodes",
        # "kubernetes.io/cluster/${var.cluster_name}" = "owned" # default ??
      }
    }

    ###############################################################
    # 2. Worker Node Group - Airbyte Sync Jobs
    ###############################################################
    # Runs: replication, check, discover jobs
    worker_nodes = {
      name           = "${var.name_prefix}-worker-nodes"
      ami_type       = "AL2023_ARM_64_STANDARD" # ARM (AWS Graviton) is usally cheaper than x86 (Intel/AMD)
      instance_types = ["r6g.large"]            # 2 vCPU, 16 GiB RAM (ARM, memory-optimized)
      disk_size      = 20
      capacity_type  = "SPOT" # cut costs by ~70%
      key_name       = var.ec2_key_name

      # auto scaling group
      min_size     = 1 # if use 0: stay as 0 if no pending pods
      max_size     = 2
      desired_size = 1 # https://github.com/bryantbiggs/eks-desired-size-hack

      # required, indicate where the node group are deployed 
      subnet_ids = module.vpc.private_subnets

      iam_instance_profile_arn = module.node_group_role.iam_instance_profile_arn

      labels = {
        "airbyte_node_type" = "worker" # Assign Airbyte worker pods
      }

      tags = {
        "Name" = "${var.name_prefix}-private-worker-nodes",

      }
    }
  }

  ###############################################################
  # Cluster Access
  ###############################################################
  # Indicates whether or not to add the cluster creator (the identity used by Terraform) as an administrator via access entry
  enable_cluster_creator_admin_permissions = false

  # Map of access entries to add to the cluster
  access_entries = {
    admin = {
      principal_arn = var.admin_principal_arn
      policy_associations = {
        admin-access = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    dev_user = {
      principal_arn = aws_iam_user.dev_user.arn
      policy_associations = {
        admin-access = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy" # TODO: add the policies required for dev_user
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  tags = {
    "Environment" = "dev"
    "Terraform"   = "true"
  }

}

####################################
# IAM role for node group
####################################
module "node_group_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.39.0"

  create_role = true
  role_name   = "${var.cluster_name}-node-group-role"

  role_description = "EKS node group role with EBS provisioning policy"

  # default is false: https://github.com/terraform-aws-modules/terraform-aws-iam/blob/master/modules/iam-assumable-role/variables.tf#L47C1-L52C1
  create_instance_profile = true

  # AWS Services that can assume these roles
  trusted_role_services = ["ec2.amazonaws.com"]

  # Attach AWS managed policies
  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    # "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ]
}

# attach a custom policy named EBSProvisioningPolicy
resource "aws_iam_role_policy" "ebs_provisioning" {
  name = "EBSProvisioningPolicy"
  role = module.node_group_role.iam_role_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateVolume",
          "ec2:DeleteVolume",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumeStatus",
          "ec2:DescribeInstances",
          "ec2:CreateTags"
        ]
        Resource = "*"
      }
    ]
  })
}
