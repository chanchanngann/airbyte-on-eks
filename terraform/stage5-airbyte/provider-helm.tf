###########################
# Helm
###########################

provider "helm" {
  # pre-requisite: EKS cluster has to be ready first, helm provider need a working kubeconfig 
  # (cluster endpoint, certificate, token) to connect to k8s API.

  # The helm provider block establishes your identity to your Kubernetes cluster. 
  # helm uses the Kubernetes provider under the hood.
  # this let helm operate just like kubectl does.
  kubernetes = {

    # The host and the cluster_ca_certificate use your aws_eks_cluster state data source 
    # to construct a method for logging in to your cluster. 

    # API endpoint of the EKS control plane
    host = data.aws_eks_cluster.default.endpoint
    # TLS certificate to trust it
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)

    # Authentication token
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.default.id]
      command     = "aws"
    }
  }
}


