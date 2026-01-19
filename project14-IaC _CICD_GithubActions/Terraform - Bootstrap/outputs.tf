output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions_role.arn
  description = "The ARN to paste into your .github/workflows/terraform.yml file in the 'role-to-assume' field."
}

output "s3_bucket_name" {
  # Updated to match your new resource name
  value       = aws_s3_bucket.ml_githubtest_tfstatefile_bucket.id
  description = "The S3 bucket name for the remote backend configuration."
}
