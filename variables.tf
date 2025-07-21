variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "aws_access_key" {
  description = "AWS access key (local testing only)"
  type        = string
}

variable "aws_secret_key" {
  description = "AWS secret key (local testing only)"
  type        = string
}

variable "azs" {
  description = "Three availability zones"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b", "us-east-2c"]
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "blocked_ip" {
  description = "IP to block in stateful firewall"
  type        = string
  default     = "198.51.100.1/32"
}

variable "environment" {
  description = "Resource environment tag"
  type        = string
  default     = "dev"
}
