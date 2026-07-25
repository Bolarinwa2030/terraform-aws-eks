# modules/vpc/outputs.tf

output "vpc_id" {
  description = "The VPC ID"
  value       = aws_vpc.vpc.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs — for EKS nodes"
  value       = aws_subnet.private[*].id
}

output "isolated_subnet_ids" {
  description = "List of isolated subnet IDs — for RDS"
  value       = aws_subnet.isolated[*].id
}