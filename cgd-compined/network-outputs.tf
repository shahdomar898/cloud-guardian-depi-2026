output "vpc_id" {
  description = "ID of the main VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the main VPC"
  value       = aws_vpc.main.cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "public_subnet_ids" {
  description = "IDs of all public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of all private subnets"
  value       = aws_subnet.private[*].id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = aws_route_table.private.id
}

output "availability_zones" {
  description = "Availability Zones used by the network"
  value       = var.availability_zones
}

output "alb_security_group_id" {
  description = "Security Group ID for the Application Load Balancer"
  value       = var.enable_alb ? aws_security_group.alb[0].id : null
}

output "ecs_tasks_security_group_id" {
  description = "Security Group ID for ECS application tasks"
  value       = aws_security_group.ecs_tasks.id
}
