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
  region = var.aws_region
  #for this part belonging to the main project and not the bootstrap, we don't need to use profile private because we are connecting via github and not my local machine
}
