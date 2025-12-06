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

####################################
# vpc
####################################

variable "vpc_cidr" {
  description = "A /16 CIDR range definition, such as 10.1.0.0/16, that the VPC will use"
  default     = "10.1.0.0/16"
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "azs" {
  description = "A list of availability zones in which to create subnets"
  type        = list(string)
}

####################################
# eks
####################################

variable "cluster_name" {
  description = "EKS cluster name"
  default     = "airbyte-eks-cluster"
}

variable "admin_principal_arn" {
  description = "ARN of the IAM user or role that should be granted cluster admin access"
  type        = string
}

variable "cluster_iam_role_name" {
  description = "Name to use on IAM role created for EKS cluster"
  type        = string
}


variable "ec2_key_name" {
  description = "EC2 Key Pair for SSH access to the worker nodes"
  type        = string
}

variable "my_ip_cidr" {
  description = "My IP"
  type        = string
}