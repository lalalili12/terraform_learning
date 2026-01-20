# This file contains variable definitions for the Terraform configuration.
# It is used to set values for AWS region, project name, database credentials, and SSH key.
aws_region   = "eu-central-1"
project_name = "shay-eks"

db_username  = "appuser"
db_password  = "SomeStrongPassword123!"
ssh_key_name = "shay-keypair"

# node_group_size = 2  # Specify the size of the node group
# instance_type = "t3.medium"  # Define the EC2 instance type for the nodes
