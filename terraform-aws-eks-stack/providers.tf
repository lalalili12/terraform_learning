terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      # Specifies the source of the AWS provider plugin
      source  = "hashicorp/aws"
      # Specifies the version constraint for the AWS provider plugin
      # The '~>' operator specifies that any version within the 5.x range is acceptable,
      # allowing for updates that do not include breaking changes.
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
