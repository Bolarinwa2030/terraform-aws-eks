variable "vpc_cidr" {
    type = string
    description= "CIDR BLOCK "
    default= "10.0.0.0/16"
}

variable "name" {
    type = string
    description= "VPC_Name"
    default= "platform_vpc"
}

variable "subnet_public_cidr"{
    type = list(string)
    default= ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    
}

variable "subnet_private_cidr" {
    type = list(string)
    default= ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "subnet_isolated_cidr" {
    type= list(string)
    default = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
}

variable "azs" {
    type= list(string)
    default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}
