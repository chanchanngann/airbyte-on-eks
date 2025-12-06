####################################
# Common 
####################################

variable "name_prefix" {
  description = "name prefix for this project"
  type        = string
}

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
}

# ####################################
# Bastion host
# ####################################

variable "my_ip_cidr" {
  description = "My IP"
  type        = string
}

variable "ec2_key_name" {
  description = "key pair name"
  type        = string
}
