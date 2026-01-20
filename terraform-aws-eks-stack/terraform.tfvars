# This file contains variable definitions for the Terraform configuration.
# It is used to set values for AWS region, project name, database credentials, and SSH key.
aws_region   = "eu-central-1"
project_name = "yuval-eks"

eks_node_group_instance_types = [ "3t.medium" ]  # Define the EC2 instance type for the eks nodes

db_username  = "appuser"
db_password  = "SomeStrongPassword123!"
ssh_key_name = "yuval-keypair"

