####################################
# 1. Namespace for Airbyte
####################################
resource "kubernetes_namespace" "airbyte" {
  metadata {
    name = "airbyte"
    labels = {
      "app.kubernetes.io/name" = "airbyte"
    }
  }
}

####################################
# 2. IAM Policy for Airbyte
####################################
resource "aws_iam_policy" "airbyte_s3_policy" {
  name        = "airbyte-s3-policy"
  description = "Allow Airbyte to access S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject*",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:ListBucketVersions",
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:aws:s3:::${var.airbyte_s3_bucket}",
          "arn:aws:s3:::${var.airbyte_s3_bucket}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "airbyte_glue_policy" {
  name        = "airbyte-glue-policy"
  description = "Allow Airbyte to access Glue"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:CreateDatabase",
          "glue:UpdateDatabase",
          "glue:DeleteDatabase",
          "glue:GetTable",
          "glue:GetTables",
          "glue:CreateTable",
          "glue:UpdateTable",
          "glue:DeleteTable",
          "glue:GetPartition",
          "glue:GetPartitions",
          "glue:CreatePartition",
          "glue:BatchCreatePartition",
          "glue:DeletePartition",
          "glue:BatchDeletePartition"
        ]
        Resource = [
          "arn:aws:glue:*:*:catalog",
          "arn:aws:glue:*:*:database/${var.glue_db_name}",
          "arn:aws:glue:*:*:table/${var.glue_db_name}/*",
          "arn:aws:glue:*:*:database/airbyte_test_namespace",
          "arn:aws:glue:*:*:table/airbyte_test_namespace/*"

        ]
      }
    ]
  })
}
####################################
# 3. IRSA for Airbyte
####################################
module "irsa-airbyte" {
  # creates a single IAM role which can be assumed by trusted resources using OpenID Connect Federated Users.
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.39.0"

  create_role  = true
  role_name    = "${var.name_prefix}-AirbyteRole"
  provider_url = replace(data.aws_eks_cluster.default.identity[0].oidc[0].issuer, "https://", "") 
  role_policy_arns = [
    aws_iam_policy.airbyte_s3_policy.arn,
    aws_iam_policy.airbyte_glue_policy.arn
  ]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${kubernetes_namespace.airbyte.metadata[0].name}:airbyte-sa"]
}

####################################
# 4. Service Account for Airbyte
####################################
resource "kubernetes_service_account" "airbyte_sa" {
  metadata {
    name      = "airbyte-sa"
    namespace = kubernetes_namespace.airbyte.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = module.irsa-airbyte.iam_role_arn
    }
  }
}

####################################
# 5. RBAC for Airbyte
####################################

resource "kubernetes_manifest" "airbyte_role" {
  manifest = yamldecode(file("${path.module}/airbyte-role.yaml"))

  depends_on = [kubernetes_service_account.airbyte_sa]
}

resource "kubernetes_manifest" "airbyte_rolebinding" {
  manifest = yamldecode(file("${path.module}/airbyte-rolebinding.yaml"))

  depends_on = [kubernetes_service_account.airbyte_sa]
}

############################################
# 6. Secret for Config DB connection info
############################################
resource "kubernetes_secret" "airbyte_config_secrets" {
  metadata {
    name      = "airbyte-config-secrets"
    namespace = "airbyte" # the same namespace where you deploy Airbyte
  }

  type = "Opaque"

  data = {
    "database-host"     = "${data.terraform_remote_state.stage4.outputs.airbyte_config_postgres_endpoint_address}"
    "database-port"     = "${data.terraform_remote_state.stage4.outputs.airbyte_config_postgres_endpoint_port}"
    "database-name"     = "${data.terraform_remote_state.stage4.outputs.airbyte_config_postgres_db_name}"
    "database-user"     = "${var.config_db_username}"
    "database-password" = "${var.config_db_password}"
  }
}

####################################
# 7. Helm install Airbyte
####################################

resource "helm_release" "airbyte" {
  name       = "airbyte-v2"
  namespace  = kubernetes_namespace.airbyte.metadata[0].name
  repository = "https://airbytehq.github.io/charts"
  chart      = "airbyte"
  version    = "2.0.12" # example version
  timeout    = 600      # 10 minutes
  wait       = true

  # Load external values.yaml instead of hardcoding
  values = [
    file("${path.module}/values.yaml")
  ]

  set = [

    {
      name  = "global.database.host"
      value = data.terraform_remote_state.stage4.outputs.airbyte_config_postgres_endpoint_address
    },

    {
      name  = "global.database.port"
      value = data.terraform_remote_state.stage4.outputs.airbyte_config_postgres_endpoint_port
    },
    {
      name  = "global.database.name"
      value = data.terraform_remote_state.stage4.outputs.airbyte_config_postgres_db_name
    },
    {
      name  = "global.storage.bucket.log"
      value = var.airbyte_s3_bucket
    },

    {
      name  = "global.storage.bucket.auditLogging"
      value = var.airbyte_s3_bucket
    },
    {
      name  = "global.storage.bucket.state"
      value = var.airbyte_s3_bucket
    },
    {
      name  = "global.storage.bucket.workloadOutput"
      value = var.airbyte_s3_bucket
    },
    {
      name  = "global.storage.bucket.activityPayload"
      value = var.airbyte_s3_bucket
    }
  ]

  depends_on = [kubernetes_namespace.airbyte]
}

