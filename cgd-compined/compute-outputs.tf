output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.app.name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.app.name
}

output "ecs_task_definition_arn" {
  description = "Registered ECS task definition ARN"
  value       = aws_ecs_task_definition.app.arn
}

output "load_balancer_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = aws_lb.app.dns_name
}

output "load_balancer_url" {
  description = "Application URL (requires a DNS record pointing to the ALB)"
  value       = "https://${aws_lb.app.dns_name}"
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for application logs"
  value       = aws_cloudwatch_log_group.app.name
}

output "ecr_endpoint_ids" {
  description = "VPC endpoint IDs used by private ECS tasks"
  value = {
    ecr_api = aws_vpc_endpoint.ecr_api.id
    ecr_dkr = aws_vpc_endpoint.ecr_dkr.id
    logs    = aws_vpc_endpoint.logs.id
    s3      = aws_vpc_endpoint.s3.id
  }
}
