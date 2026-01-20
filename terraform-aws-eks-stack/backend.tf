terraform {
  # Configure the backend to use Amazon S3 for storing the Terraform state file
  backend "s3" {
    bucket         = "shay-terraform-state-bucket" # Name of the S3 bucket
    key            = "eks-stack/terraform.tfstate" # Path to the state file within the bucket
    region         = "eu-central-1"               # AWS region where the S3 bucket is located
    dynamodb_table = "terraform-locks"            # DynamoDB table for state locking and consistency
    encrypt        = true                          # Enable server-side encryption for the state file
  }
}
