variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "cloud-guardian-depi-2026"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the main VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability Zones used by the network"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least two Availability Zones are required."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) == length(var.availability_zones)
    error_message = "The number of public subnet CIDRs must match the number of Availability Zones."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private application subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) == length(var.availability_zones)
    error_message = "The number of private subnet CIDRs must match the number of Availability Zones."
  }
}
variable "enable_dns_support" {
  description = "Enable DNS support inside the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames inside the VPC"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common tags applied to network resources"
  type        = map(string)

  default = {
    Project     = "cloud-guardian-depi-2026"
    Environment = "dev"
    ManagedBy   = "Terraform"
    Component   = "Network"
  }
}
variable "container_app_port" {
  description = "Port used by the containerized application"
  type        = number
  default     = 8080
}

variable "enable_alb" {
  description = "Whether the application will use an Application Load Balancer"
  type        = bool
  default     = true
}
