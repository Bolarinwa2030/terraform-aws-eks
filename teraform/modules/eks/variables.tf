variable "cluster_name" {
    description = "Name of the EKS Cluster"
    type = string
}

variable "kubernetes_version" {
    description = "Kubernetes version to use"
    type = string
    default = "1.32"
}

variable "private_subnet_ids" {
    description = "List of private subnet IDs from the VPC module"
    type = list(string)
}

variable "node_group_system_instance_type" {
    description = "EC2 instance type for system node group"
    type = string
    default = "t3.medium"
}

variable "node_group_app_instance_type" {
    description = "EC2 instance type for app node group"
    type = string
    default = "t3.large"
}