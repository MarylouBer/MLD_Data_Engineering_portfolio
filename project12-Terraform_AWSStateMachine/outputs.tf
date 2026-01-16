
output "valid_sqs_queue_url" {
  description = "The URL of the SQS queue containing validated messages."
  value       = aws_sqs_queue.valid_message_queue.id
}

output "invalid_sqs_queue_url" {
  description = "The URL of the SQS queue containing invalid messages."
  value       = aws_sqs_queue.invalid_message_queue.id
}

output "dead_letter_topic_arn" {
  description = "The ARN of the SNS Topic used for Step Function error handling."
  value       = aws_sns_topic.dead_letter_topic.arn
}

output "step_function_arn" {
  description = "The ARN of the Step Function State Machine."
  value       = aws_sfn_state_machine.message_validator.arn
}

output "step_function_name" {
  description = "The name of the Step Function State Machine."
  value       = aws_sfn_state_machine.message_validator.name
}

output "lambda_function_name" {
  description = "The name of the Lambda function that validates the message."
  value       = aws_lambda_function.sqs_processor_lambda.function_name
}

output "lambda_function_arn" {
  description = "The ARN of the Lambda function."
  value       = aws_lambda_function.sqs_processor_lambda.arn
}
