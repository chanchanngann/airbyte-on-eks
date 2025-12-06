####################################
# S3 bucket for Airbyte
####################################
resource "aws_s3_bucket" "airbyte_bucket" {
  bucket = var.airbyte_s3_bucket

  lifecycle {
    prevent_destroy = true
  }
  
  tags = {
    Name        = "Airbyte logs"
    Description = "Bucket for Airbyte on EKS"
  }
}