# This file configures the Terraform providers required for the project.
# It defines the minimum version of Terraform and the providers that will be used
# to interact with cloud services like AWS.
# -----------------------------------------------------------------------------

# This block specifies the required versions for Terraform and its providers.
# It ensures that the project runs with compatible versions to prevent unexpected errors.
terraform {
  required_version = "~> 1.2"

  required_providers {
    # This specifies the AWS provider, including its source and a version constraint.
    # The `~> 4.15.0` constraint ensures that Terraform uses a version of the
    # provider greater than or equal to 4.15.0 but less than 5.0.0.
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.15.0"
    }
  }
}

# This block configures the AWS provider with a specific region and profile.
# It tells Terraform where to deploy the resources (`var.aws_region`) and which
# AWS credentials profile to use for authentication (`profile = "saml"`).
provider "aws" {
  region  = var.aws_region
  profile = "saml"
}

