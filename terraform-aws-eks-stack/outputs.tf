// Output the ID of the VPC created by the VPC module
output "vpc_id" {
  value = module.vpc.vpc_id
}

// Output the name of the EKS cluster created by the EKS module
output "eks_cluster_name" {
  value = module.eks.cluster_name
}

// Output the endpoint of the EKS cluster created by the EKS module
output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

// Output the endpoint of the RDS instance created by the RDS module
output "rds_endpoint" {
  value = module.rds.db_endpoint
}

output "eks_ami_release_version" {
  value = module.eks.aws_eks_node_group.release_version
}

output "instance_types" {
  value = module.eks.aws_eks_node_group.instance_types
}