terraform {
  # Configure the backend to use Amazon S3 for storing the Terraform state file
  backend "s3" {
    bucket         = "${var.project_name}-terraform-state-bucket" # Name of the S3 bucket
    key            = "${var.project_name}/terraform.tfstate" # Path to the state file within the bucket
    region         = "${var.aws_region}"               # AWS region where the S3 bucket is located
    dynamodb_table = "terraform-locks"            # DynamoDB table for state locking and consistency
    encrypt        = true                          # Enable server-side encryption for the state file
  }
}
