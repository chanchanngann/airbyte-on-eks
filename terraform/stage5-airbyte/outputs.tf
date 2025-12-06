####################################
# Airbyte
####################################

output "airbyte_sa" {
  value       = kubernetes_service_account.airbyte_sa.metadata[0].name
  description = "service account for airbyte"
}

output "airbyte_s3_bucket" {
  value       = aws_s3_bucket.airbyte_bucket.id
  description = "Bucket for Airbyte on EKS"
}

output "airbyte_iam_role_arn" {
  value = module.irsa-airbyte.iam_role_arn
}

output "airbyte_iam_role_name" {
  value = module.irsa-airbyte.iam_role_name
}

