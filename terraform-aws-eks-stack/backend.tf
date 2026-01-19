terraform {
  backend "s3" {
    bucket         = "shay-terraform-state-bucket"
    key            = "eks-stack/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
