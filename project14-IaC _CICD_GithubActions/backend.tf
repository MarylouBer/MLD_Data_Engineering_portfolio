terraform {
  backend "s3" {
    bucket       = "terraform-githubtest-tfstatefile-bucket-mld01"
    key          = "global/sqs/terraform.tfstate" # I updated path to reflect it's an SQS project
    region       = "eu-north-1"
    profile      = "private"
    encrypt      = true
    use_lockfile = true
  }
}
