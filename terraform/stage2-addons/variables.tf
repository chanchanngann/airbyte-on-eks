####################################
# common
####################################

variable "name_prefix" {
  description = "name prefix for tag"
  type        = string
}

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  default     = "airbyte-eks-cluster"
}
