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
# RDS - airbyte_config_postgres
# ####################################

variable "config_db" {
  description = "Initial database of RDS Postrgres"
  type        = string
}

variable "config_db_username" {
  description = "credentials to access RDS Postgres"
  type        = string
  sensitive   = true
}

variable "config_db_password" {
  description = "credentials to access RDS Postgres"
  type        = string
  sensitive   = true
}


####################################
# Airbyte 
####################################

variable "cluster_name" {
  description = "EKS cluster name"
  default     = "airbyte-eks-cluster"
}

variable "airbyte_s3_bucket" {
  type        = string
  description = "S3 bucket for Airbyte"
}


####################################
# Glue catalog
####################################

variable "glue_db_name" {
  description = "destination DB name registered in Glue catalog"
}
