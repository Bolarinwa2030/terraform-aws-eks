variable "name" {
  description = "Name prefix for all RDS resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID from the VPC module"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs — RDS lives here, no internet access"
  type        = list(string)
}

variable "eks_node_security_group_id" {
  description = "Security group of EKS nodes — only they can reach RDS"
  type        = string
}

variable "db_name" {
  description = "Name of the initial database"
  type        = string
  default     = "orders"
}

variable "db_username" {
  description = "Master username"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Master password — passed in from Secrets Manager, never hardcoded"
  type        = string
  sensitive   = true  # Terraform will never print this in logs
}

variable "instance_class" {
  description = "RDS instance size"
  type        = string
  default     = "db.t3.micro"  # cheap for dev; use db.t3.medium for prod
}