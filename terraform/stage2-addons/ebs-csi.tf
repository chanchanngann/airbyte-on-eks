####################################
# IRSA for EBS CSI 
####################################
# Creates single IAM role which can be assumed by trusted resources using OpenID Connect Federated Users.
module "irsa-ebs-csi-controller" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.39.0"

  create_role                   = true
  role_name                     = "${var.name_prefix}-EBSCSIRole"
  provider_url                  = replace(data.aws_eks_cluster.default.identity[0].oidc[0].issuer, "https://", "")
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

module "irsa-ebs-csi-driver-node" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.39.0"

  create_role  = false
  role_name    = data.aws_iam_role.node_group_role.name
  provider_url = replace(data.aws_eks_cluster.default.identity[0].oidc[0].issuer, "https://", "")

  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-driver-node-sa"]
}

####################################
# Service Account for EBS CSI
####################################
resource "kubernetes_service_account" "ebs-csi-controller-sa" {
  metadata {
    name      = "ebs-csi-controller-sa"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"      = "ebs-csi-controller"
      "app.kubernetes.io/component" = "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = module.irsa-ebs-csi-controller.iam_role_arn
    }
  }
}

resource "kubernetes_service_account" "ebs-csi-driver-node-sa" {
  metadata {
    name      = "ebs-csi-driver-node-sa"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.irsa-ebs-csi-driver-node.iam_role_arn
    }
  }
}


####################################
# Helm resource: EBS CSI Driver
####################################

resource "helm_release" "ebs_csi" {
  name       = "aws-ebs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart      = "aws-ebs-csi-driver"
  namespace  = "kube-system"
  version    = "2.47.0"

  set = [

    {
      name  = "controller.serviceAccount.create"
      value = "false"
    },

    {
      name  = "controller.serviceAccount.name"
      value = "ebs-csi-controller-sa"
    },

    {
      name  = "node.serviceAccount.create"
      value = "false"
    },

    {
      name  = "node.serviceAccount.name"
      value = "ebs-csi-driver-node-sa"
    },


    {
      name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = module.irsa-ebs-csi-controller.iam_role_arn
    },
    {
      name  = "node.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = module.irsa-ebs-csi-driver-node.iam_role_arn
    }
  ]


}