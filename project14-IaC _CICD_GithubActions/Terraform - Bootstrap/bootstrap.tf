# --- OIDC BOOTSTRAP COMPONENTS ---
# This project is designed to be run manually ONCE to create the backend resources
# and the OIDC IAM role that your GitHub Action will assume.



# This data block fetches the thumbprint for GitHub's OIDC issuer URL.
data "tls_certificate" "github_actions_oidc" {
  url = "https://token.actions.githubusercontent.com"
}

# AWS OIDC Identity Provider
# This registers GitHub as a trusted external identity provider in your AWS account.
resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github_actions_oidc.certificates[0].sha1_fingerprint]
  tags            = var.default_tags
}


# S3 Bucket for Terraform State
resource "aws_s3_bucket" "ml_githubtest_tfstatefile_bucket" {
  bucket = "terraform-githubtest-tfstatefile-bucket-mld01"
  tags   = var.default_tags
}

resource "aws_s3_bucket_versioning" "versioning_mld_githubtest_tfstatefile_bucket" {
  # 2. UPDATED LINK: Now points to the new resource name
  bucket = aws_s3_bucket.ml_githubtest_tfstatefile_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "mld_githubtest_tfstatefile_bucket" {
  bucket                  = aws_s3_bucket.ml_githubtest_tfstatefile_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# IAM Role for GitHub Actions (OIDC)
resource "aws_iam_role" "github_actions_role" {
  name = "GitHubActionsTerraformRole"
  tags = var.default_tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com",
            "token.actions.githubusercontent.com:sub" : "repo:MarylouBer/MLD_Data_Engineering_portfolio:*"
          }
        }
      },
    ]
  })
}

# IAM Policy: Allow access to the Backend Bucket (State file)
resource "aws_iam_role_policy" "backend_access" {
  name = "backend_access_policy"
  role = aws_iam_role.github_actions_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.ml_githubtest_tfstatefile_bucket.arn,
          "${aws_s3_bucket.ml_githubtest_tfstatefile_bucket.arn}/*",
        ]
      }
    ]
  })
}

# This AWS Managed Policy allows full control over SQS, but NOTHING else.
# The robot cannot create EC2s, delete databases, or touch your billing.
resource "aws_iam_role_policy_attachment" "github_actions_sqs" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

# Required data source to get your AWS Account ID for the OIDC provider ARN
data "aws_caller_identity" "current" {}
