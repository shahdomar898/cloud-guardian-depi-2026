variable "container_image" {
  description = "Full image URI in Amazon ECR, including tag or digest"
  type        = string

  validation {
    condition     = can(regex("\\.dkr\\.ecr\\.[a-z0-9-]+\\.amazonaws\\.com/", var.container_image))
    error_message = "container_image must be an Amazon ECR image URI."
  }
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN in the same AWS Region as the ALB (us-east-1)"
  type        = string
}

variable "container_cpu" {
  description = "Fargate task CPU units"
  type        = number
  default     = 512
}

variable "container_memory" {
  description = "Fargate task memory in MiB"
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Number of ECS tasks to run"
  type        = number
  default     = 1
}

variable "health_check_path" {
  description = "HTTP path used by the ALB target group health check"
  type        = string
  default     = "/actuator/health"
}

variable "app_environment" {
  description = "Non-sensitive environment variables passed to the container"
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period"
  type        = number
  default     = 14
}
