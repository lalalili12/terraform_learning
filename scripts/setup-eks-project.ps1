$base = "C:\Users\ashay\Documents\terraform-aws-eks-stack"

# Create directories
$dirs = @(
  $base,
  "$base\modules",
  "$base\modules\vpc",
  "$base\modules\iam",
  "$base\modules\eks",
  "$base\modules\rds",
  "$base\modules\s3",
  "$base\modules\cloudwatch"
)

foreach ($d in $dirs) {
  if (-not (Test-Path $d)) {
    New-Item -ItemType Directory -Path $d | Out-Null
  }
}

# ---------- Root files ----------

@"
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
"@ | Set-Content "$base\providers.tf"

@"
terraform {
  backend "s3" {
    bucket         = "shay-terraform-state-bucket"
    key            = "eks-stack/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
"@ | Set-Content "$base\backend.tf"

@"
variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "eu-central-1"
}

variable "project_name" {
  type        = string
  description = "Project name prefix"
  default     = "shay-eks"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "eks_version" {
  type    = string
  default = "1.29"
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "ssh_key_name" {
  type        = string
  description = "Existing EC2 key pair name for EKS nodes"
}
"@ | Set-Content "$base\variables.tf"

@"
aws_region   = "eu-central-1"
project_name = "shay-eks"

db_username  = "appuser"
db_password  = "SomeStrongPassword123!"
ssh_key_name = "shay-keypair"
"@ | Set-Content "$base\terraform.tfvars"

@"
module "vpc" {
  source          = "./modules/vpc"
  project_name    = var.project_name
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
}

module "iam" {
  source       = "./modules/iam"
  project_name = var.project_name
}

module "eks" {
  source          = "./modules/eks"
  project_name    = var.project_name
  cluster_version = var.eks_version

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  cluster_role_arn = module.iam.eks_cluster_role_arn
  node_role_arn    = module.iam.eks_node_role_arn
  ssh_key_name     = var.ssh_key_name
}

module "rds" {
  source       = "./modules/rds"
  project_name = var.project_name

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  eks_sg_id          = module.eks.node_sg_id

  db_username = var.db_username
  db_password = var.db_password
}

module "s3" {
  source       = "./modules/s3"
  project_name = var.project_name
}

module "cloudwatch" {
  source           = "./modules/cloudwatch"
  project_name     = var.project_name
  eks_cluster_name = module.eks.cluster_name
}
"@ | Set-Content "$base\main.tf"

@"
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "rds_endpoint" {
  value = module.rds.db_endpoint
}
"@ | Set-Content "$base\outputs.tf"

# ---------- Module: VPC ----------

@"
variable "project_name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}
"@ | Set-Content "$base\modules\vpc\variables.tf"

@"
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_subnet" "public" {
  for_each = toset(var.public_subnets)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-${each.value}"
  }
}

resource "aws_subnet" "private" {
  for_each = toset(var.private_subnets)

  vpc_id     = aws_vpc.this.id
  cidr_block = each.value

  tags = {
    Name = "${var.project_name}-private-${each.value}"
  }
}
"@ | Set-Content "$base\modules\vpc\main.tf"

@"
output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  value = [for s in aws_subnet.private : s.id]
}
"@ | Set-Content "$base\modules\vpc\outputs.tf"

# ---------- Module: IAM ----------

@"
variable "project_name" {
  type = string
}
"@ | Set-Content "$base\modules\iam\variables.tf"

@"
data "aws_iam_policy_document" "eks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_cluster_role" {
  name               = "${var.project_name}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role.json
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

data "aws_iam_policy_document" "eks_node_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_node_role" {
  name               = "${var.project_name}-eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role.json
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ecr_read_only" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
"@ | Set-Content "$base\modules\iam\main.tf"

@"
output "eks_cluster_role_arn" {
  value = aws_iam_role.eks_cluster_role.arn
}

output "eks_node_role_arn" {
  value = aws_iam_role.eks_node_role.arn
}
"@ | Set-Content "$base\modules\iam\outputs.tf"

# ---------- Module: EKS ----------

@"
variable "project_name" {
  type = string
}

variable "cluster_version" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "cluster_role_arn" {
  type = string
}

variable "node_role_arn" {
  type = string
}

variable "ssh_key_name" {
  type = string
}
"@ | Set-Content "$base\modules\eks\variables.tf"

@"
resource "aws_security_group" "eks_nodes" {
  name        = "${var.project_name}-eks-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-eks-nodes-sg"
  }
}

resource "aws_eks_cluster" "this" {
  name     = "${var.project_name}-cluster"
  role_arn = var.cluster_role_arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids = var.private_subnet_ids
  }

  depends_on = [aws_security_group.eks_nodes]
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.project_name}-node-group"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"]

  remote_access {
    ec2_ssh_key = var.ssh_key_name
  }
}
"@ | Set-Content "$base\modules\eks\main.tf"

@"
output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "node_sg_id" {
  value = aws_security_group.eks_nodes.id
}
"@ | Set-Content "$base\modules\eks\outputs.tf"

# ---------- Module: RDS ----------

@"
variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "eks_sg_id" {
  type = string
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}
"@ | Set-Content "$base\modules\rds\variables.tf"

@"
resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg"
  description = "DB security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.eks_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "this" {
  identifier        = "${var.project_name}-db"
  engine            = "postgres"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]

  skip_final_snapshot = true
}
"@ | Set-Content "$base\modules\rds\main.tf"

@"
output "db_endpoint" {
  value = aws_db_instance.this.address
}
"@ | Set-Content "$base\modules\rds\outputs.tf"

# ---------- Module: S3 ----------

@"
variable "project_name" {
  type = string
}
"@ | Set-Content "$base\modules\s3\variables.tf"

@"
resource "aws_s3_bucket" "app_bucket" {
  bucket = "${var.project_name}-app-bucket"

  tags = {
    Name = "${var.project_name}-app-bucket"
  }
}

resource "aws_s3_bucket_versioning" "app_bucket_versioning" {
  bucket = aws_s3_bucket.app_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}
"@ | Set-Content "$base\modules\s3\main.tf"

@"
output "app_bucket_name" {
  value = aws_s3_bucket.app_bucket.bucket
}
"@ | Set-Content "$base\modules\s3\outputs.tf"

# ---------- Module: CloudWatch ----------

@"
variable "project_name" {
  type = string
}

variable "eks_cluster_name" {
  type = string
}
"@ | Set-Content "$base\modules\cloudwatch\variables.tf"

@"
resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.eks_cluster_name}/cluster"
  retention_in_days = 30
}
"@ | Set-Content "$base\modules\cloudwatch\main.tf"

@"
output "eks_log_group_name" {
  value = aws_cloudwatch_log_group.eks.name
}
"@ | Set-Content "$base\modules\cloudwatch\outputs.tf"

# ---------- Cheatsheet ----------

@"
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
"@ | Set-Content "$base\cheatsheet.md"

# ---------- Questions ----------

@"
# Practice Questions

## VPC, NACL, SG
1. Explain the difference between a public and private subnet.
2. How does a NAT Gateway differ from an Internet Gateway?
3. What is the difference between a NACL and a Security Group? When would you use each?
4. How would you restrict access so that only EKS nodes can reach an RDS instance?
5. What happens if you accidentally associate the wrong route table with a subnet?

## IAM
6. What is the difference between an IAM user, group, and role?
7. Why are IAM roles preferred over long-lived access keys?
8. What is least privilege and how do you apply it in IAM policies?
9. How does an assume role policy differ from a permission policy?
10. How would you allow a Kubernetes service account to access an S3 bucket securely?

## EC2, S3, RDS
11. What factors influence your choice of EC2 instance type?
12. How would you secure an S3 bucket that stores Terraform state?
13. What is an RDS subnet group and why is it required?
14. How do you allow only specific security groups to access an RDS instance?
15. What are the trade-offs between RDS and running your own DB on EC2?

## CloudWatch
16. What’s the difference between CloudWatch metrics and logs?
17. How would you set up an alarm for high CPU on an RDS instance?
18. Where would you look to debug a failing EKS pod from an AWS perspective?
19. How can you control log retention and cost in CloudWatch?

## EKS
20. Explain the difference between the EKS control plane and worker nodes.
21. How does EKS networking work (CNI, pod IPs, node IPs)?
22. What are managed node groups and why use them?
23. How would you expose a service in EKS to the internet?
24. How would you securely connect an EKS app to an RDS database?
25. What is IRSA and why is it better than using node IAM roles for everything?

## Terraform
26. What is Terraform state and why is it important?
27. What are the benefits of using remote state with S3 and DynamoDB?
28. Explain the difference between a resource and a module.
29. How do you structure Terraform for multiple environments (dev/stage/prod)?
30. What happens if someone changes resources manually in AWS outside Terraform? How do you handle drift?
31. What is `terraform taint` and when would you use it?
32. How do you pass sensitive values (like DB passwords) into Terraform safely?
"@ | Set-Content "$base\questions.md"

# ---------- Architecture diagram (text) ----------

@"
# Architecture Overview

## Physical Architecture (EKS + VPC + RDS + S3 + IAM + CloudWatch)

\`\`\`
┌──────────────────────────────────────────────────────────────────────────────┐
│                                AWS ACCOUNT                                   │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐  │
│  │                                VPC (10.0.0.0/16)                        │  │
│  │                                                                          │  │
│  │  ┌──────────────────────────────┐   ┌──────────────────────────────┐    │  │
│  │  │     Public Subnet A          │   │     Public Subnet B          │    │  │
│  │  │     10.0.1.0/24              │   │     10.0.2.0/24              │    │  │
│  │  │                              │   │                              │    │  │
│  │  │  - NAT Gateway               │   │  - (optional) Bastion Host   │    │  │
│  │  │  - Route to IGW              │   │  - Route to IGW              │    │  │
│  │  └──────────────────────────────┘   └──────────────────────────────┘    │  │
│  │                                                                          │  │
│  │  ┌──────────────────────────────┐   ┌──────────────────────────────┐    │  │
│  │  │     Private Subnet A         │   │     Private Subnet B         │    │  │
│  │  │     10.0.11.0/24             │   │     10.0.12.0/24             │    │  │
│  │  │                              │   │                              │    │  │
│  │  │  - EKS Worker Nodes          │   │  - EKS Worker Nodes          │    │  │
│  │  │  - RDS Instance (Postgres)   │   │  - RDS Standby (if Multi-AZ) │    │  │
│  │  │  - Route to NAT Gateway      │   │  - Route to NAT Gateway      │    │  │
│  │  └──────────────────────────────┘   └──────────────────────────────┘    │  │
│  │                                                                          │  │
│  │  ┌────────────────────────────────────────────────────────────────────┐  │  │
│  │  │                         EKS Control Plane                          │  │  │
│  │  │                     (AWS-managed, not in your VPC)                 │  │  │
│  │  │                                                                    │  │  │
│  │  │  - API Server                                                      │  │  │
│  │  │  - etcd                                                            │  │  │
│  │  │  - Cluster management                                              │  │  │
│  │  │  - Communicates with worker nodes via ENIs in private subnets      │  │  │
│  │  └────────────────────────────────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐  │
│  │                                S3 Buckets                              │  │
│  │  - Terraform state bucket                                              │  │
│  │  - App assets bucket                                                   │  │
│  └────────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐  │
│  │                                IAM Roles                               │  │
│  │  - EKS Cluster Role                                                    │  │
│  │  - EKS Node Role                                                       │  │
│  │  - RDS Monitoring Role (optional)                                      │  │
│  │  - Policies for CloudWatch, ECR, S3                                    │  │
│  └────────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐  │
│  │                               CloudWatch                               │  │
│  │  - Log groups for EKS                                                  │  │
│  │  - Metrics for RDS                                                     │  │
│  │  - Alarms (CPU, storage, etc.)                                         │  │
│  └────────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────────┘
\`\`\`

## Traffic Flow Summary

- Users → Internet → LoadBalancer/Service → EKS Nodes → Pods → RDS
- EKS Nodes → NAT Gateway → Internet (for images/updates)
- Terraform → AWS (via IAM) → State in S3, locks in DynamoDB

- RDS:
  - In private subnets
  - Security group allows only EKS node SG on port 5432

- EKS:
  - Control plane managed by AWS
  - Worker nodes in private subnets
  - Node SG controls access to pods and RDS

- S3:
  - Terraform state bucket (remote backend)
  - App bucket for assets/logs

- CloudWatch:
  - Central place for logs and metrics
  - Alarms for RDS CPU, etc.
"@ | Set-Content "$base\architecture.md"

# ---------- Answers (detailed) ----------

@"
# Detailed Answers

## VPC, NACL, SG

1. Difference between public and private subnet  
A public subnet has a route to an Internet Gateway (IGW). Instances can have public IPs and talk directly to the internet.  
A private subnet has no route to IGW. Outbound internet access goes through a NAT Gateway; inbound from the internet is not possible.

2. NAT Gateway vs Internet Gateway  
- NAT Gateway: outbound-only for private subnets, no inbound from internet, used so private instances can reach the internet.  
- Internet Gateway: bidirectional, used by public subnets to allow public access.

3. NACL vs Security Group  
- NACL: stateless, subnet-level, ordered rules, supports allow and deny.  
- Security Group: stateful, instance/ENI-level, allow-only rules, most commonly used for access control.

4. Restrict access so only EKS nodes reach RDS  
Put RDS in private subnets. Create an RDS security group that allows inbound on port 5432 only from the EKS node security group. No public access, no CIDR ranges.

5. Wrong route table associated with subnet  
You can break internet access, accidentally expose private subnets, or isolate resources. EKS nodes may fail to join, RDS may become unreachable, and debugging becomes harder.

## IAM

6. IAM user vs group vs role  
- User: individual identity for a person.  
- Group: collection of users to share policies.  
- Role: identity assumed temporarily by users or services, with its own permissions.

7. Why roles instead of long-lived access keys  
Roles use temporary credentials that rotate automatically, reducing risk. Long-lived keys can leak, be hard to rotate, and violate least privilege.

8. Least privilege  
Grant only the minimum permissions needed to perform a task. For example, give `s3:GetObject` instead of `s3:*` if the app only reads objects.

9. Assume role policy vs permission policy  
- Assume role (trust) policy: defines who can assume the role.  
- Permission policy: defines what the role can do once assumed.

10. Allow Kubernetes service account to access S3  
Use IRSA: create an IAM role with trust to the EKS OIDC provider, attach S3 permissions, and annotate the Kubernetes service account with the role ARN so pods get temporary credentials.

## EC2, S3, RDS

11. Choosing EC2 instance type  
Consider CPU, memory, network, storage performance, cost, and workload type (compute-heavy, memory-heavy, GPU, general purpose).

12. Secure S3 bucket for Terraform state  
Block public access, enable encryption, enable versioning, restrict IAM access to Terraform roles only, and use DynamoDB for state locking.

13. What is an RDS subnet group  
A collection of subnets (usually private) in different AZs where RDS is allowed to place DB instances. Required so RDS knows where it can deploy.

14. Allow only specific SGs to access RDS  
In the RDS security group, set inbound rules with source = EKS node SG and port = DB port (e.g., 5432). No CIDR ranges.

15. RDS vs DB on EC2  
RDS: managed backups, patching, Multi-AZ, easier operations but less OS control and usually higher cost.  
EC2 DB: full control, potentially cheaper, but you manage backups, patching, HA, and failover.

## CloudWatch

16. Metrics vs logs  
Metrics are numeric time-series (CPU, latency). Logs are raw text output from applications and systems.

17. Alarm for high RDS CPU  
Create a CloudWatch alarm on the `CPUUtilization` metric for the RDS instance, with a threshold (e.g., > 80% for several periods) and an action (SNS notification).

18. Debug failing EKS pod from AWS perspective  
Check CloudWatch logs, node health, ENIs and IPs, security groups, VPC CNI plugin, and IAM permissions (especially if using IRSA).

19. Control CloudWatch cost  
Set log retention policies, delete unused log groups, avoid overly verbose logging, and use filters to reduce ingestion.

## EKS

20. Control plane vs worker nodes  
Control plane is AWS-managed (API server, etcd, scheduler). Worker nodes are EC2 instances in your VPC running your pods.

21. EKS networking  
Pods get IPs from the VPC CIDR via the CNI plugin. Nodes have ENIs in subnets. Services use kube-proxy and iptables to route traffic.

22. Managed node groups  
AWS manages lifecycle (provisioning, scaling, patching, draining) of worker nodes. You define instance types and sizes; AWS handles the heavy lifting.

23. Expose service to internet  
Use a Kubernetes Service of type `LoadBalancer`. AWS creates an external load balancer and routes traffic to your pods.

24. Securely connect EKS app to RDS  
Place RDS in private subnets, restrict RDS SG to EKS node SG, store DB credentials in Kubernetes Secrets, and avoid public access.

25. What is IRSA  
IAM Roles for Service Accounts: maps Kubernetes service accounts to IAM roles so pods get temporary AWS credentials, enabling fine-grained permissions per workload.

## Terraform

26. What is Terraform state  
A file that stores Terraform's view of the current infrastructure. Used to detect changes and plan updates.

27. Benefits of remote state  
Shared across team, supports locking (with DynamoDB), versioned, more secure, and prevents conflicting changes.

28. Resource vs module  
Resource: single infrastructure object (e.g., `aws_instance`).  
Module: a collection of resources packaged together for reuse.

29. Multi-environment structure  
Use separate directories or workspaces for dev/stage/prod, with shared modules and environment-specific variables.

30. Manual changes outside Terraform  
Terraform detects drift. You can import resources, re-apply Terraform to overwrite manual changes, or manually revert them.

31. terraform taint  
Marks a resource as tainted so Terraform will destroy and recreate it on the next apply. Useful when a resource is broken or misconfigured.

32. Passing sensitive values  
Use sensitive variables, `.tfvars` files not committed to Git, environment variables, or secret managers. Never hard-code secrets in `.tf` files.
"@ | Set-Content "$base\answers.md"

Write-Host "Project created at: $base"