variable "db_password" {
  description = "RDS master password — set via TF_VAR_db_password environment variable"
  type        = string
  sensitive   = true
}