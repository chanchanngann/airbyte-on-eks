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

data "terraform_remote_state" "stage3" {
  backend = "local"
  config = {
    path = "../stage3-bastion/terraform.tfstate"
  }
}