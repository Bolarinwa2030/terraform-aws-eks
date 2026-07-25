output "db_endpoint" {
  description = "Connection endpoint — goes into your app config as DB_HOST"
  value       = aws_db_instance.main.endpoint
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

output "db_port" {
  description = "PostgreSQL port"
  value       = aws_db_instance.main.port
}