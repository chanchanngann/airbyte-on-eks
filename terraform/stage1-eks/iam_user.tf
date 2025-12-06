####################################
# IAM user
####################################

resource "aws_iam_user" "dev_user" {
  name = "eks-dev-user"
}

resource "aws_iam_access_key" "dev_user_key" {
  user = aws_iam_user.dev_user.name
}

resource "aws_iam_user_policy" "eks_cluster_access" {
  name = "eks-cluster-access"
  user = aws_iam_user.dev_user.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "eks:DescribeCluster",
          "eks:ListAccessEntries",
          "eks:AccessKubernetesApi"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}
