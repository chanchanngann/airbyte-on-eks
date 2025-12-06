###################################
# RDS - airbyte_config_postgres
###################################

output "airbyte_config_postgres_endpoint_address" {
  value = aws_db_instance.airbyte_config_postgres.address
}

output "airbyte_config_postgres_endpoint_port" {
  value = aws_db_instance.airbyte_config_postgres.port
}

output "airbyte_config_postgres_db_name" {
  value = aws_db_instance.airbyte_config_postgres.db_name
}

output "airbyte_config_postgres_username" {
  value = aws_db_instance.airbyte_config_postgres.username
  sensitive = true
}

output "airbyte_config_postgres_password" {
  value     = aws_db_instance.airbyte_config_postgres.password
  sensitive = true
}

###################################
# RDS - cdc_source_postgres
###################################
output "cdc_source_postgres_endpoint_address" {
  value = aws_db_instance.cdc_source_postgres.address
}

output "cdc_source_postgres_endpoint_port" {
  value = aws_db_instance.cdc_source_postgres.port
}

output "cdc_source_postgres_db_name" {
  value = aws_db_instance.cdc_source_postgres.db_name
}

output "cdc_source_postgres_username" {
  value = aws_db_instance.cdc_source_postgres.username
  sensitive = true
}

output "cdc_source_postgres_password" {
  value     = aws_db_instance.cdc_source_postgres.password
  sensitive = true
}

