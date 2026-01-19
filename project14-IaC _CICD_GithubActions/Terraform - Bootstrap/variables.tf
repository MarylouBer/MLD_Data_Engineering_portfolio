variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "eu-north-1"
}

variable "default_tags" {
  type = map(string)
  default = {
    project_id = "1001"
  }
}
