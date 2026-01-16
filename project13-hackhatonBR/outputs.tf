# This file defines the outputs of the Terraform configuration.
# Outputs are used to display important information to the user after
# `terraform apply` and to pass data to other configurations.
# -----------------------------------------------------------------------------

# Output the ARN of the created Lambda function. This is useful for
# referencing the function in other AWS services or configurations.
output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.order_processing_lambda.arn
}

# Output the name of the created Lambda function. This is often used
# in conjunction with its ARN for cross-resource referencing.
output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.order_processing_lambda.function_name
}

# Output the URL of the SQS queue for order picking.
output "sqs_order_picking_queue_url" {
  description = "URL of the SQS order picking queue"
  value       = aws_sqs_queue.sqs_order_picking.url
}

# Output the URL of the SQS queue for panic alerts.
output "sqs_panic_alert_queue_url" {
  description = "URL of the SQS panic alert queue"
  value       = aws_sqs_queue.sqs_panic_alert.url
}

# Output the URL of the SQS queue for real-time box data.
output "sqs_realtime_box_queue_url" {
  description = "URL of the SQS realtime box queue"
  value       = aws_sqs_queue.sqs_realtime_box.url
}

# Output the URL of the SQS queue for spoiled food alerts.
output "sqs_spoiled_food_queue_url" {
  description = "URL of the spoiled food SQS queue"
  value       = aws_sqs_queue.sqs_spoiled_food.url
}

# Output the URL of the SQS queue for accident alerts.
output "sqs_accident_queue_url" {
  description = "URL of the SQS accident queue"
  value       = aws_sqs_queue.sqs_accident.url
}

# Output the ARN of the Secrets Manager secret. This can be used for
# granting access to other resources.
output "secrets_manager_arn" {
  description = "ARN of the Secrets Manager secret for the API token"
  value       = data.aws_secretsmanager_secret.bumpy_ride_api_key.arn
}
