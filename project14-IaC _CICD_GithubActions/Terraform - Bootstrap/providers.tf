terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.20.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "private" #It tells Terraform to authenticate using the specific set of AWS credentials stored under the name [private] in your local computer's configuration file.
}
