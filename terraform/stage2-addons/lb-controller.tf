####################################
# IAM Policy for ALB Controller
####################################
resource "aws_iam_policy" "alb_controller_ingress_policy" {
  name        = "alb-controller-ingress-policy"
  description = "Custom policy for ALB Controller"

  # the file should be put in the same folder as main.tf in order to fetch the correct file path
  # path.module returns the absolute path to the directory where the current .tf file is located.
  policy = file("${path.module}/ingress-policy.json")
}

####################################
# IRSA for ALB Controller
####################################
module "irsa-lb-controller" {
  # creates a single IAM role which can be assumed by trusted resources using OpenID Connect Federated Users.
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.39.0"

  create_role  = true
  role_name    = "${var.name_prefix}-LBControllerRole"
  provider_url = replace(data.aws_eks_cluster.default.identity[0].oidc[0].issuer, "https://", "")
  role_policy_arns = [
    aws_iam_policy.alb_controller_ingress_policy.arn
  ]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:aws-load-balancer-controller-sa"]
}

####################################
# Service Account for ALB Controller
####################################
resource "kubernetes_service_account" "alb" {
  metadata {
    name      = "aws-load-balancer-controller-sa"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = module.irsa-lb-controller.iam_role_arn
    }
  }
}

####################################
# Helm resource: ALB Controller
####################################

resource "helm_release" "alb_controller" {

  # note: The load balancer controller uses tags to discover subnets 
  # in which it can create load balancers. 
  # We also need to update terraform vpc module to include them. 
  # public_subnet_tags = {"kubernetes.io/role/elb" = "1"}
  # private_subnet_tags = {"kubernetes.io/role/internal-elb" = "1"}

  name       = "${var.name_prefix}-aws-lb-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.8.0"

  # custom configuration for the chart
  # values = [
  #   file("${path.module}/alb-values.yaml")
  # ]

  # we need this dependency coz here only values are referenced, not the resource itself
  # if resource we dont need the dependency
  # depends_on = [kubernetes_service_account.alb]

  # alternative for values.yaml
  # set specific values in values.yaml
  set = [

    {
      name  = "clusterName"
      value = var.cluster_name
    },

    # dont let helm chart to create a default SA (without IRSA annotation)
    # will create it in IAM module (irsa)
    {
      name  = "serviceAccount.create"
      value = "false"
    },

    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller-sa"
    },

    {
      name  = "region"
      value = var.region
    },

    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = module.irsa-lb-controller.iam_role_arn
    },

    {
      name  = "vpcId"
      value = data.terraform_remote_state.stage1.outputs.vpc_id
    },
  ]

}
