# Network Architecture
## Secure Cloud Applications, DevOps & Compliance by Design

### 1. Overview
The network foundation provides an isolated AWS VPC for the application infrastructure.
It separates public-facing components from private application workloads.

### 2. VPC Configuration

| Component | Configuration |
|---|---|
| AWS Region | us-east-1 |
| VPC CIDR | 10.0.0.0/16 |
| Availability Zones | us-east-1a, us-east-1b |
| Public Subnets | 10.0.1.0/24, 10.0.2.0/24 |
| Private Subnets | 10.0.11.0/24, 10.0.12.0/24 |
| DNS Support | Enabled |
| DNS Hostnames | Enabled |

### 3. Network Design

- One VPC contains the project network.
- Two public subnets are distributed across two Availability Zones.
- Two private subnets are distributed across two Availability Zones.
- An Internet Gateway is attached to the VPC.
- Public subnets use a route table with a default route to the Internet Gateway.
- Private subnets use a separate route table without a direct Internet Gateway route.

### 4. Workload Placement

| Workload | Intended Placement |
|---|---|
| Application Load Balancer | Public subnets |
| ECS Tasks | Private subnets |

ECS Fargate is a proposed deployment assumption and must be confirmed by the team.

### 5. Security Groups

#### ALB Security Group
- Allows inbound HTTPS traffic on TCP 443.
- Allows outbound application traffic to the ECS security group.
- Application traffic uses the configurable container port.

#### ECS Tasks Security Group
- Allows inbound application traffic only from the ALB security group.
- Allows outbound HTTPS traffic on TCP 443.

The current application port is 8080 as a placeholder. Confirm the actual port with the application team.

### 6. Routing and Connectivity

Public subnet route:
- 0.0.0.0/0 -> Internet Gateway

Private subnet:
- No direct Internet Gateway route.
- NAT Gateway or VPC Endpoints are not included in this initial foundation.

A security-group egress rule alone does not provide internet connectivity. Private workloads will need an approved NAT Gateway or suitable VPC Endpoints if they require outbound access.

### 7. Cost and Security Decisions

- NAT Gateways are intentionally excluded pending team approval because they incur ongoing charges.
- VPC Flow Logs are deferred pending logging architecture, IAM permissions, and cost approval.
- Interface VPC Endpoints are deferred until required AWS services are identified.
- AWS WAF configuration should be coordinated with the security workstream.
- No custom Network ACLs are introduced; Security Groups provide the initial workload-level controls.

### 8. Assumptions Requiring Team Confirmation

1. Whether the application will use an Application Load Balancer.
2. Whether ECS will use Fargate or EC2 launch type.
3. The actual application container port.
4. Whether private workloads require NAT Gateway or VPC Endpoints.
5. Whether database resources require a dedicated Security Group.

### 9. Ownership and Deployment

This directory contains the Network workstream Terraform configuration.
The team member prepares and reviews the configuration and submits a Pull Request.

Shared backend configuration and AWS deployment are controlled by the team leader.
Do not run terraform apply as a team member.
