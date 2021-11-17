output "cluster_name" {
value = var.cluster_name
}

output "region" {
value = var.region
}

output "destroy" {
value = var.destroy
}

output "endpoint" {
  value = aws_eks_cluster.primary[*].endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.primary[*].certificate_authority[0].data
}
