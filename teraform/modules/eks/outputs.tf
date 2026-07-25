output "cluster_name" {
  description = "EKS cluster name — used by other modules and CI"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "API server endpoint — what kubectl talks to"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_ca_certificate" {
  description = "Certificate to verify the cluster is genuine"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "oidc_provider_arn" {
  description = "Used by IAM module to create IRSA roles for pods"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  description = "Used by IAM module to build trust policies"
  value       = aws_iam_openid_connect_provider.eks.url
}

output "node_security_group_id" {
  description = "Security group on EKS nodes — RDS allows traffic from this"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}