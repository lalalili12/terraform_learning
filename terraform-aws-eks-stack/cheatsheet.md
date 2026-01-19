# AWS + Terraform Cheat Sheet

## VPC
- VPC: private network in AWS.
- Public subnet: route to IGW, can have public IPs.
- Private subnet: route to NAT, no direct internet.
- Key Terraform:
  - aws_vpc
  - aws_subnet
  - aws_internet_gateway
  - aws_nat_gateway
  - aws_route_table

## NACL vs Security Group
- NACL:
  - Stateless, subnet-level.
  - Separate inbound/outbound rules.
  - Evaluated in order.
- Security Group:
  - Stateful, instance/ENI-level.
  - Allow rules only.
  - Most common for app access control.

## IAM
- User: human identity.
- Role: assumed by users/services.
- Policy: JSON doc with Allow/Deny.
- Trust policy: who can assume the role.
- Permission policy: what the role can do.
- Terraform:
  - aws_iam_role
  - aws_iam_policy
  - aws_iam_role_policy_attachment

## EC2
- Virtual machine.
- Needs:
  - AMI
  - Instance type
  - Security group
  - Key pair
- Terraform:
  - aws_instance
  - aws_ebs_volume
  - aws_ebs_attachment

## S3
- Object storage.
- Use cases:
  - Terraform state
  - Logs
  - Assets
- Terraform:
  - aws_s3_bucket
  - aws_s3_bucket_versioning
  - aws_s3_bucket_server_side_encryption_configuration

## RDS
- Managed relational DB.
- Needs:
  - Engine (postgres/mysql)
  - Instance class
  - Subnet group
  - Security group
- Terraform:
  - aws_db_instance
  - aws_db_subnet_group

## CloudWatch
- Metrics, logs, alarms.
- Terraform:
  - aws_cloudwatch_log_group
  - aws_cloudwatch_metric_alarm

## EKS
- Managed Kubernetes control plane.
- Needs:
  - VPC + subnets
  - IAM roles (cluster + nodes)
  - Node groups
- Terraform:
  - aws_eks_cluster
  - aws_eks_node_group

## Terraform Core Commands
- terraform init
- terraform plan
- terraform apply
- terraform destroy
- terraform fmt
- terraform validate

## Terraform Concepts
- Provider: plugin for a platform (aws).
- Resource: creates/updates infrastructure.
- Data source: reads existing data.
- Module: reusable group of resources.
- State: current view of infra.
- Backend: where state is stored (e.g., S3).
