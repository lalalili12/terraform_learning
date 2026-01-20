module "vpc" {
  # VPC module to create and manage the Virtual Private Cloud and its subnets
  source          = "./modules/vpc"
  project_name    = var.project_name
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
}

module "iam" {
  # IAM module to create roles and policies for EKS
  source       = "./modules/iam"
  project_name = var.project_name
}

module "eks" {
  # EKS module to create and manage the Kubernetes cluster
  source          = "./modules/eks"
  project_name    = var.project_name
  eks_version     = var.eks_version

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  cluster_role_arn = module.iam.eks_cluster_role_arn
  node_role_arn    = module.iam.eks_node_role_arn
  ssh_key_name     = var.ssh_key_name
}

module "rds" {
  # RDS module to create and manage the relational database service
  source       = "./modules/rds"
  project_name = var.project_name

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  eks_sg_id          = module.eks.node_sg_id

  db_username = var.db_username
  db_password = var.db_password
}

module "s3" {
  # S3 module to create and manage S3 buckets
  source       = "./modules/s3"
  project_name = var.project_name
}

module "cloudwatch" {
  # CloudWatch module to set up monitoring and logging for the EKS cluster
  source           = "./modules/cloudwatch"
  project_name     = var.project_name
  cluster_name = module.eks.cluster_name
}
