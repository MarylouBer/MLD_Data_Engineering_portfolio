terraform {
  backend "s3" {
    bucket       = "terraform-githubtest-tfstatefile-bucket-mld01"
    key          = "global/sqs/terraform.tfstate"
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true
  }
}
