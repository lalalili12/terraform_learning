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
