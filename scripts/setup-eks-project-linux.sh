#!/bin/bash

BASE="/home/<your-username>/Documents/terraform-aws-eks-stack"

# Create directories
mkdir -p "$BASE/modules/vpc"
mkdir -p "$BASE/modules/iam"
mkdir -p "$BASE/modules/eks"
mkdir -p "$BASE/modules/rds"
mkdir -p "$BASE/modules/s3"
mkdir -p "$BASE/modules/cloudwatch"

############################################
# Root Terraform Files
############################################

cat > "$BASE/providers.tf" << 'EOF'
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
EOF

cat > "$BASE/backend.tf" << 'EOF'
terraform {
  backend "s3" {
    bucket         = "shay-terraform-state-bucket"
    key            = "eks-stack/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
EOF

cat > "$BASE/variables.tf" << 'EOF'
variable "aws_region" {
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  type        = string
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
  type = string
}
EOF

cat > "$BASE/terraform.tfvars" << 'EOF'
aws_region   = "eu-central-1"
project_name = "shay-eks"

db_username  = "appuser"
db_password  = "SomeStrongPassword123!"
ssh_key_name = "shay-keypair"
EOF

cat > "$BASE/main.tf" << 'EOF'
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
EOF

cat > "$BASE/outputs.tf" << 'EOF'
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
EOF

############################################
# VPC Module
############################################

cat > "$BASE/modules/vpc/variables.tf" << 'EOF'
variable "project_name" { type = string }
variable "vpc_cidr" { type = string }
variable "public_subnets" { type = list(string) }
variable "private_subnets" { type = list(string) }
EOF

cat > "$BASE/modules/vpc/main.tf" << 'EOF'
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.project_name}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "${var.project_name}-igw" }
}

resource "aws_subnet" "public" {
  for_each = toset(var.public_subnets)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  map_public_ip_on_launch = true

  tags = { Name = "${var.project_name}-public-${each.value}" }
}

resource "aws_subnet" "private" {
  for_each = toset(var.private_subnets)

  vpc_id     = aws_vpc.this.id
  cidr_block = each.value

  tags = { Name = "${var.project_name}-private-${each.value}" }
}
EOF

cat > "$BASE/modules/vpc/outputs.tf" << 'EOF'
output "vpc_id" { value = aws_vpc.this.id }
output "public_subnet_ids" { value = [for s in aws_subnet.public : s.id] }
output "private_subnet_ids" { value = [for s in aws_subnet.private : s.id] }
EOF

############################################
# IAM Module
############################################

cat > "$BASE/modules/iam/variables.tf" << 'EOF'
variable "project_name" { type = string }
EOF

cat > "$BASE/modules/iam/main.tf" << 'EOF'
data "aws_iam_policy_document" "eks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals { type = "Service", identifiers = ["eks.amazonaws.com"] }
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
    principals { type = "Service", identifiers = ["ec2.amazonaws.com"] }
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
EOF

cat > "$BASE/modules/iam/outputs.tf" << 'EOF'
output "eks_cluster_role_arn" { value = aws_iam_role.eks_cluster_role.arn }
output "eks_node_role_arn" { value = aws_iam_role.eks_node_role.arn }
EOF

############################################
# EKS Module
############################################

cat > "$BASE/modules/eks/variables.tf" << 'EOF'
variable "project_name" { type = string }
variable "cluster_version" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "cluster_role_arn" { type = string }
variable "node_role_arn" { type = string }
variable "ssh_key_name" { type = string }
EOF

cat > "$BASE/modules/eks/main.tf" << 'EOF'
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

  tags = { Name = "${var.project_name}-eks-nodes-sg" }
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
EOF

cat > "$BASE/modules/eks/outputs.tf" << 'EOF'
output "cluster_name" { value = aws_eks_cluster.this.name }
output "cluster_endpoint" { value = aws_eks_cluster.this.endpoint }
output "node_sg_id" { value = aws_security_group.eks_nodes.id }
EOF

############################################
# RDS Module
############################################

cat > "$BASE/modules/rds/variables.tf" << 'EOF'
variable "project_name" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "eks_sg_id" { type = string }
variable "db_username" { type = string }
variable "db_password" { type = string }
EOF

cat > "$BASE/modules/rds/main.tf" << 'EOF'
resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = { Name = "${var.project_name}-db-subnet-group" }
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
EOF

cat > "$BASE/modules/rds/outputs.tf" << 'EOF'
output "db_endpoint" { value = aws_db_instance.this.address }
EOF

############################################
# S3 Module
############################################

cat > "$BASE/modules/s3/variables.tf" << 'EOF'
variable "project_name" { type = string }
EOF

cat > "$BASE/modules/s3/main.tf" << 'EOF'
resource "aws_s3_bucket" "app_bucket" {
  bucket = "${var.project_name}-app-bucket"

  tags = { Name = "${var.project_name}-app-bucket" }
}

resource "aws_s3_bucket_versioning" "app_bucket_versioning" {
  bucket = aws_s3_bucket.app_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}
EOF

cat > "$BASE/modules/s3/outputs.tf" << 'EOF'
output "app_bucket_name" { value = aws_s3_bucket.app_bucket.bucket }
EOF

############################################
# CloudWatch Module
############################################

cat > "$BASE/modules/cloudwatch/variables.tf" << 'EOF'
variable "project_name" { type = string }
variable "eks_cluster_name" { type = string }
EOF

cat > "$BASE/modules/cloudwatch/main.tf" << 'EOF'
resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.eks_cluster_name}/cluster"
  retention_in_days = 30
}
EOF

cat > "$BASE/modules/cloudwatch/outputs.tf" << 'EOF'
output "eks_log_group_name" { value = aws_cloudwatch_log_group.eks.name }
EOF

############################################
# Cheatsheet
############################################

cat > "$BASE/cheatsheet.md" << 'EOF'
# AWS + Terraform Cheat Sheet
(…same content as before…)
EOF

############################################
# Questions
############################################

cat > "$BASE/questions.md" << 'EOF'
# Practice Questions
(…same content as before…)
EOF

############################################
# Architecture Diagram
############################################

cat > "$BASE/architecture.md" << 'EOF'
# Architecture Overview
(…full physical diagram…)
EOF

############################################
# Answers
############################################

cat > "$BASE/answers.md" << 'EOF'
# Detailed Answers
(…full detailed answers…)
EOF

echo "Project created at: $BASE"