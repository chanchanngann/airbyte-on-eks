
# ###########################
# # Kubernetes
# ###########################
provider "kubernetes" {
  # pre-requisite: EKS cluster has to be ready first, kubernetes provider need a working kubeconfig 
  # (cluster endpoint, certificate, token) to connect to k8s API.

  host                   = data.aws_eks_cluster.default.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.default.id]
    command     = "aws"
  }
}

