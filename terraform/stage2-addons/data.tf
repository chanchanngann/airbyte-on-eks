# note: Terraform’s data blocks are read-only lookups, 
# and they execute before any resources are created.
# so if the resource hasn't been created yet, you are not able to read its data source.

###############################
# common
###############################

# safe to run before the cluster is created because it just prepares an IAM token
# data "aws_eks_cluster_auth" "default" {
#   # name = module.eks.cluster_name
#   name = var.cluster_name
# }


# To get the cluster's endpoint and CA cert
# fail if the cluster doesn’t exist yet (coz it queries real cluster metadata from AWS)
data "aws_eks_cluster" "default" {
  name = var.cluster_name

}

###############################
# ebs csi
###############################

# https://aws.amazon.com/blogs/containers/amazon-ebs-csi-driver-is-now-generally-available-in-amazon-eks-add-ons/ 
data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

data "aws_iam_role" "node_group_role" {
  name = "${var.cluster_name}-node-group-role"
}

###############################################
# remote state
###############################################

data "terraform_remote_state" "stage1" {
  backend = "local"
  config = {
    path = "../stage1-eks/terraform.tfstate"
  }
}