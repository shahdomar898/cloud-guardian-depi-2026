# cloud-guardian-depi-2026

Terraform configuration for the **network foundation** and **compute (ECS Fargate + Application Load Balancer)** workloads of the Cloud Guardian project.

This is the combined configuration of two workstreams:

- **Network foundation** — VPC, subnets, Internet Gateway, route tables, security groups
- **Compute** — ECS Fargate service, Application Load Balancer, task definition, IAM roles, CloudWatch logs

## Repository structure

| Path / File | Description |
|---|---|
| `network.tf` | VPC, subnets, Internet Gateway, route tables, associations, security groups |
| `network-variables.tf` | Network input variables |
| `network-outputs.tf` | VPC, subnet, route table, security group IDs |
| `compute.tf` | ECS cluster/service, task definition, ALB, target group, listeners, IAM, CloudWatch log group, VPC endpoints |
| `compute-variables.tf` | Compute input variables |
| `compute-outputs.tf` | Compute outputs |
| `backend.tf` | S3 backend + provider requirements |

## Prerequisites

- Terraform **>= 1.10** (v1.17.2 recommended)
- AWS credentials / AWS CLI profile (`depi-team-n`) with permission to manage the resources
- An S3 bucket (`cloud-guardian-depi-2026`) for the Terraform state backend, with DynamoDB locking

## Get started

```bash
# 1. Initialise (installs providers; skips backend configuration)
terraform init -backend=false

# 2. Validate the configuration
terraform validate

# 3. Preview the changes
terraform plan

# 4. Apply
terraform apply
