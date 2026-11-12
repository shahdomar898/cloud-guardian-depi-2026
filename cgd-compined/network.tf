# Main VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-igw"
  })
}
# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-${count.index + 1}"
    Tier = "Public"
  })
}

# Private Application Subnets
resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-private-${count.index + 1}"
    Tier = "Private"
  })
}
# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-rt"
    Tier = "Public"
  })
}

# Public Internet Route
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-private-rt"
    Tier = "Private"
  })
}

# Associate Private Subnets with Private Route Table
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
# ==========================================
# Application Load Balancer Security Group
# ==========================================

resource "aws_security_group" "alb" {
  count = var.enable_alb ? 1 : 0

  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for the Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress = []
  egress  = []

  tags = merge(var.common_tags, {
    Name      = "${var.project_name}-${var.environment}-alb-sg"
    Component = "ALB"
  })
}

# Allow HTTPS traffic from the Internet to ALB
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  count = var.enable_alb ? 1 : 0

  security_group_id = aws_security_group.alb[0].id
  description       = "Allow HTTPS from the Internet"

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_ipv4   = "0.0.0.0/0"
}

# Allow ALB to communicate with ECS Tasks
resource "aws_vpc_security_group_egress_rule" "alb_to_ecs" {
  count = var.enable_alb ? 1 : 0

  security_group_id            = aws_security_group.alb[0].id
  referenced_security_group_id = aws_security_group.ecs_tasks.id
  description                  = "Allow traffic from ALB to ECS tasks"

  ip_protocol = "tcp"
  from_port   = var.container_app_port
  to_port     = var.container_app_port
}

# ==========================================
# ECS Tasks Security Group
# ==========================================

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-${var.environment}-ecs-sg"
  description = "Security group for ECS application tasks"
  vpc_id      = aws_vpc.main.id

  ingress = []
  egress  = []

  tags = merge(var.common_tags, {
    Name      = "${var.project_name}-${var.environment}-ecs-sg"
    Component = "ECS"
  })
}

# Allow application traffic only from ALB
resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  count = var.enable_alb ? 1 : 0

  security_group_id            = aws_security_group.ecs_tasks.id
  referenced_security_group_id = aws_security_group.alb[0].id
  description                  = "Allow application traffic only from ALB"

  ip_protocol = "tcp"
  from_port   = var.container_app_port
  to_port     = var.container_app_port
}

# Allow HTTPS outbound traffic from ECS tasks
resource "aws_vpc_security_group_egress_rule" "ecs_https_outbound" {
  security_group_id = aws_security_group.ecs_tasks.id
  description       = "Allow HTTPS outbound traffic"

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_ipv4   = "0.0.0.0/0"
}