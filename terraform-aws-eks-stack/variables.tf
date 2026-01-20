# The AWS region where resources will be created.
variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "eu-central-1"
}

# This variable is used to set a prefix for naming resources in the project.
variable "project_name" {
  type        = string
  description = "Project name prefix"
  default     = "shay-eks"
}

# CIDR block for the VPC.
variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
}

# List of CIDR blocks for public subnets.
variable "public_subnets" {
   type = map(object({
    cidr = string
    az   = string
  }))
  default = {
    public1 = {
      cidr = "10.0.1.0/24"
      az   = "eu-central-1a"
    }
    public2 = {
      cidr = "10.0.2.0/24"
      az   = "eu-central-1b"
    }
  }
}

# List of CIDR blocks for private subnets.
# List of availability zones for private subnets.

variable "private_subnets" {
  type = map(object({
    cidr = string
    az   = string
  }))  
  default = {
    subnet1 = {
      cidr = "10.0.11.0/24"
      az   = "eu-central-1a"
    } 
    subnet2 = {
      cidr = "10.0.12.0/24"
      az   = "eu-central-1b"
    }
  }
} 


# Kubernetes version for the EKS cluster.
variable "eks_version" {
  type    = string
  default = "1.29"
}

# variable "eks_node_group_instance_types" {
#   type = list(string)
# }

# Username for the database (sensitive).
variable "db_username" {
  type      = string
  sensitive = true
}

# Password for the database (sensitive).
variable "db_password" {
  type      = string
  sensitive = true
}

# Name of the SSH key pair for EC2 instances in the EKS cluster.
variable "ssh_key_name" {
  type        = string
  description = "Existing EC2 key pair name for EKS nodes"
}
