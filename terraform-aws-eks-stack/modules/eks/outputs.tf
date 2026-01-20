output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "node_sg_id" {
  value = aws_security_group.eks_nodes.id
}

output "instance_types" {
  value = aws_eks_node_group.this.instance_types
}

output "release_version" {
  value = aws_eks_node_group.this.release_version 
}