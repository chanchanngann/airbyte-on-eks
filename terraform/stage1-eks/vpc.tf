####################################
# VPC
####################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "${var.name_prefix}-vpc"

  cidr = var.vpc_cidr
  azs  = var.azs

  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  # The number of public subnet CIDR blocks specified in public_subnets must 
  # be greater than or equal to the number of availability zones specified in var.azs. 
  # This is to ensure that each NAT Gateway has a dedicated public subnet to deploy to.

  # to enable endpoint private access for EKS cluster : https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Additional tags for the public subnets
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1 # tell AWS LoadBalancer controller where to 
    # place public load balancers (external apps)
    # when a Kubernetes Service of type LoadBalancer is created.

    # "kubernetes.io/cluster/${var.cluster_name}" = "shared"  # required to tell EKS cluster the subnets are part of the EKS cluster
    # "shared" means multiple clusters can share it (a shared VPC)
    # If the tag is missing, AWS-managed load balancers may fail to create, 
    # or Kubernetes can’t discover the subnets.
    # optional if use EKS module coz EKS module will add this tag automatically itself
  }

  # Additional tags for the private subnets
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1 # Tells EKS this subnet can host internal LoadBalancers (within VPC only)
    # when you add the following annotation to your services (in k8s)
    # service.beta.kubernetes.io/aws-load-balancer-internal: "true"

    # "kubernetes.io/cluster/${var.cluster_name}" = "shared"  

  }

  tags = {
    "Name"        = "${var.name_prefix}-vpc"
    "Environment" = "dev"
    "Terraform"   = "true"
  }
}