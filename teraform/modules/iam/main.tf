# ──────────────────────────────────────────
# HOW IRSA WORKS (read this first):
#
# Normal way (bad): store AWS keys inside the pod as env vars.
# If the pod is hacked, the attacker gets the keys.
#
# IRSA way (good): the pod has a Kubernetes Service Account.
# That Service Account is mapped to an IAM Role.
# When the pod starts, it gets a short-lived token.
# It exchanges that token with AWS for temporary credentials.
# No stored secrets anywhere.
# ──────────────────────────────────────────


# ──────────────────────────────────────────
# 1. ORDER SERVICE ROLE
# order-service needs to: read/write to SQS
# (to send events to notification-service)
# ──────────────────────────────────────────
resource "aws_iam_role" "order_service" {
  name = "${var.cluster_name}-order-service"

  # This trust policy says:
  # "Only the order-service ServiceAccount in the dev namespace
  #  is allowed to assume this role — nobody else"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:dev:order-service"
          "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "order_service" {
  name = "order-service-policy"
  role = aws_iam_role.order_service.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Can send and receive SQS messages
        Effect   = "Allow"
        Action   = ["sqs:SendMessage", "sqs:ReceiveMessage", "sqs:DeleteMessage"]
        Resource = "arn:aws:sqs:*:${var.aws_account_id}:order-*"
      },
      {
        # Can read its own secrets from Secrets Manager
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = "arn:aws:secretsmanager:*:${var.aws_account_id}:secret:order-service/*"
      }
    ]
  })
}


# ──────────────────────────────────────────
# 2. INVENTORY SERVICE ROLE
# inventory-service needs to: read from S3
# (product catalog stored there)
# ──────────────────────────────────────────
resource "aws_iam_role" "inventory_service" {
  name = "${var.cluster_name}-inventory-service"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:dev:inventory-service"
          "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "inventory_service" {
  name = "inventory-service-policy"
  role = aws_iam_role.inventory_service.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = [
          "arn:aws:s3:::${var.cluster_name}-inventory",
          "arn:aws:s3:::${var.cluster_name}-inventory/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = "arn:aws:secretsmanager:*:${var.aws_account_id}:secret:inventory-service/*"
      }
    ]
  })
}


# ──────────────────────────────────────────
# 3. NOTIFICATION SERVICE ROLE
# notification-service needs to: send emails
# via SES, and read from SQS
# ──────────────────────────────────────────
resource "aws_iam_role" "notification_service" {
  name = "${var.cluster_name}-notification-service"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:dev:notification-service"
          "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "notification_service" {
  name = "notification-service-policy"
  role = aws_iam_role.notification_service.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ses:SendEmail", "ses:SendRawEmail"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
        Resource = "arn:aws:sqs:*:${var.aws_account_id}:order-*"
      }
    ]
  })
}

# ──────────────────────────────────────────
# GITHUB ACTIONS OIDC ROLE
# This allows GitHub Actions to push images
# to ECR and update the GitOps repo
# WITHOUT storing any AWS keys in GitHub.
#
# How it works:
# GitHub generates a short-lived token per job
# AWS verifies the token came from YOUR repo
# GitHub Actions gets temporary AWS credentials
# No secrets stored anywhere
# ──────────────────────────────────────────
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "github_actions" {
  name = "github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          # Only YOUR repo can assume this role
          "token.actions.githubusercontent.com:sub" = "repo:Bolarinwa2030/terraform-aws-eks:*"
        }
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "github_actions" {
  name = "github-actions-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Push and pull Docker images from ECR
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      }
    ]
  })
}