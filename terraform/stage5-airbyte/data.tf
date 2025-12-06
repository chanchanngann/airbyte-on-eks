# note: Terraform’s data blocks are read-only lookups, 
# and they execute before any resources are created.
# so if the resource hasn't been created yet, you are not able to read its data source.

###############################################
# remote state
###############################################

data "terraform_remote_state" "stage1" {
  backend = "local"
  config = {
    path = "../stage1-eks/terraform.tfstate"
  }
}

data "terraform_remote_state" "stage4" {
  backend = "local"
  config = {
    path = "../stage4-rds/terraform.tfstate"
  }
}

###############################
# EKS cluster
###############################

# To get the cluster's endpoint and CA cert
# fail if the cluster doesn’t exist yet (coz it queries real cluster metadata from AWS)
data "aws_eks_cluster" "default" {
  name = var.cluster_name

}