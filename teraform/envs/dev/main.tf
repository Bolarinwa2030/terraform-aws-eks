terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws" 
      version = "~> 5.0"       
    }
  }
}

provider "aws" {
  region = "us-east-1" 
}

# ── MODULE 1: VPC ──────────────────────────────────────
module "vpc" {
  source = "../../modules/vpc"

  name                 = "platform-eks-dev" # fixed: was unclosed string
  vpc_cidr             = "10.0.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b", "us-east-1c"]
  subnet_public_cidr   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  subnet_private_cidr  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  subnet_isolated_cidr = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
}

# ── MODULE 2: EKS — Kubernetes Cluster ─────────────────
module "eks" {
  source = "../../modules/eks"

  cluster_name       = "platform-eks-dev"
  kubernetes_version = "1.32"
  private_subnet_ids = module.vpc.private_subnet_ids
}

# ── MODULE 3: IAM ───────────────────────────────────────
module "iam" {
  source = "../../modules/iam" # fixed: was "../.../modules/iam"

  cluster_name      = "platform-eks-dev"
  oidc_provider_arn = module.eks.oidc_provider_arn # fixed: "modules" → "module", "arm" → "arn"
  oidc_provider_url = module.eks.oidc_provider_url # fixed: "modules" → "module"
  aws_account_id    = "071680046254"
}

# ── MODULE 4: RDS ───────────────────────────────────────
module "rds" {
  source = "../../modules/rds"

  name                       = "platform-eks-dev" # fixed: was cluster_name
  vpc_id                     = module.vpc.vpc_id  # fixed: was oidc_provider_arn = module.vpc.vpc.id
  private_subnet_ids         = module.vpc.isolated_subnet_ids
  db_password                = var.db_password
  eks_node_security_group_id = module.eks.node_security_group_id
}