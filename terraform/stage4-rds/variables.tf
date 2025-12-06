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
  sensitive = true
}

variable "config_db_password" {
  description = "credentials to access RDS Postgres"
  type        = string
  sensitive = true
}

# ####################################
# RDS - cdc_source_postgres
# ####################################

variable "cdc_db" {
  description = "Initial database of RDS Postrgres"
  type        = string
}

variable "cdc_db_username" {
  description = "credentials to access RDS Postgres"
  type        = string
  sensitive = true
}

variable "cdc_db_password" {
  description = "credentials to access RDS Postgres"
  type        = string
  sensitive = true
}
