# ==========================================
# Compute: ECS Fargate + Application Load Balancer
# Depends on network resources defined in network.tf.
# ==========================================

locals {
  compute_name = "${var.project_name}-${var.environment}"
  container_name = "${local.compute_name}-app"
}

# CloudWatch log group for application container logs
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${local.compute_name}/app"
  retention_in_days = var.log_retention_days

  tags = merge(var.common_tags, {
    Name      = "${local.compute_name}-app-logs"
    Component = "Compute"
  })
}

# ECS task execution role: permits ECS/Fargate to pull ECR images
# and publish container logs to CloudWatch.
resource "aws_iam_role" "ecs_task_execution" {
  name = "${local.compute_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.common_tags, {
    Component = "Compute"
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS cluster
resource "aws_ecs_cluster" "app" {
  name = "${local.compute_name}-cluster"

  tags = merge(var.common_tags, {
    Name      = "${local.compute_name}-cluster"
    Component = "Compute"
  })
}

# Application Load Balancer in public subnets
resource "aws_lb" "app" {
  name               = substr("${local.compute_name}-alb", 0, 32)
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb[0].id]
  subnets            = aws_subnet.public[*].id

  depends_on = [aws_internet_gateway.main]

  tags = merge(var.common_tags, {
    Name      = "${local.compute_name}-alb"
    Component = "Compute"
  })
}

resource "aws_lb_target_group" "app" {
  name        = substr("${local.compute_name}-tg", 0, 32)
  port        = var.container_app_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = merge(var.common_tags, {
    Name      = "${local.compute_name}-target-group"
    Component = "Compute"
  })
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.app.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.acm_certificate_arn
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# ECS task definition
resource "aws_ecs_task_definition" "app" {
  family                   = "${local.compute_name}-app"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = local.container_name
      image     = var.container_image
      essential = true

      portMappings = [{
        name          = "http"
        containerPort = var.container_app_port
        hostPort      = var.container_app_port
        protocol      = "tcp"
      }]

      environment = [
        for key, value in var.app_environment : {
          name  = key
          value = value
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = data.aws_region.current.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = merge(var.common_tags, {
    Name      = "${local.compute_name}-task"
    Component = "Compute"
  })

  depends_on = [aws_iam_role_policy_attachment.ecs_task_execution]
}

data "aws_region" "current" {}

# ECS service runs tasks in private subnets. Tasks do not receive public IPs.
resource "aws_ecs_service" "app" {
  name            = "${local.compute_name}-service"
  cluster         = aws_ecs_cluster.app.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  platform_version = "LATEST"

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = local.container_name
    container_port   = var.container_app_port
  }

  depends_on = [
    aws_lb_listener.https,
    aws_iam_role_policy_attachment.ecs_task_execution,
    aws_vpc_endpoint.ecr_api,
    aws_vpc_endpoint.ecr_dkr,
    aws_vpc_endpoint.logs,
    aws_vpc_endpoint.s3
  ]

  tags = merge(var.common_tags, {
    Name      = "${local.compute_name}-service"
    Component = "Compute"
  })
}

# ==========================================
# VPC endpoints required by private Fargate tasks
# These avoid requiring a NAT Gateway just to pull ECR images
# and send logs to CloudWatch.
# ==========================================

resource "aws_security_group" "vpc_endpoints" {
  name        = "${local.compute_name}-vpce-sg"
  description = "HTTPS from ECS tasks to interface VPC endpoints"
  vpc_id      = aws_vpc.main.id

  ingress = []
  egress  = []

  tags = merge(var.common_tags, {
    Name      = "${local.compute_name}-vpce-sg"
    Component = "Compute"
  })
}

resource "aws_vpc_security_group_ingress_rule" "vpce_from_ecs" {
  security_group_id            = aws_security_group.vpc_endpoints.id
  referenced_security_group_id = aws_security_group.ecs_tasks.id
  description                  = "HTTPS from ECS tasks to VPC endpoints"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.common_tags, {
    Name      = "${local.compute_name}-ecr-api"
    Component = "Compute"
  })
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.common_tags, {
    Name      = "${local.compute_name}-ecr-dkr"
    Component = "Compute"
  })
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(var.common_tags, {
    Name      = "${local.compute_name}-cloudwatch-logs"
    Component = "Compute"
  })
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = merge(var.common_tags, {
    Name      = "${local.compute_name}-s3-endpoint"
    Component = "Compute"
  })
}
