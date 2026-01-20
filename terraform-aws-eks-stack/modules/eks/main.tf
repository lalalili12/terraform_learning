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
  version  = var.eks_version

  vpc_config {
    subnet_ids = var.private_subnet_ids
  }

  depends_on = [aws_security_group.eks_nodes]

  tags = {
    Name = "${var.project_name}-eks-cluster"
  }
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.project_name}-eks-node-group"
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

  tags = {
    Name = "${var.project_name}-eks-node-group"
  }
}
