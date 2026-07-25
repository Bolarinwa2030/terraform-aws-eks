output "order_service_role_arn" {
  description = "Annotate the order-service Kubernetes ServiceAccount with this"
  value       = aws_iam_role.order_service.arn
}

output "inventory_service_role_arn" {
  description = "Annotate the inventory-service Kubernetes ServiceAccount with this"
  value       = aws_iam_role.inventory_service.arn
}

output "notification_service_role_arn" {
  description = "Annotate the notification-service Kubernetes ServiceAccount with this"
  value       = aws_iam_role.notification_service.arn
}

output "github_actions_role_arn" {
  description = "Role ARN for GitHub Actions — paste this into ci.yaml"
  value       = aws_iam_role.github_actions.arn
}