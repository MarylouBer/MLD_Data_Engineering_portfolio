data "aws_caller_identity" "current" {}

#### SQS Queues ####

resource "aws_sqs_queue" "valid_message_queue" {
  name = var.valid_queue_name
  tags = var.default_tags
}


resource "aws_sqs_queue" "invalid_message_queue" {
  name = var.invalid_queue_name
  tags = var.default_tags
}

resource "aws_sqs_queue" "message_in_queue" {
  name = var.input_queue_name
  tags = var.default_tags
}

resource "aws_sns_topic" "dead_letter_topic" {
  name = var.dead_letter_topic_name
  tags = var.default_tags
}


##### Lambda IAM Role and Policy ####

resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.lambda_function_name}_role"
  tags = var.default_tags
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}


resource "aws_iam_policy" "lambda_sqs_policy" {
  name = "${var.lambda_function_name}_sqs_policy"
  tags = var.default_tags
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.message_in_queue.arn
      },
      {
        Effect = "Allow"
        Action = "states:StartExecution"
        Resource = [
          aws_sfn_state_machine.message_validator.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_sqs_policy.arn
}


#### SQS Event Source Mapping (The flow starter) ####

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.message_in_queue.arn
  function_name    = aws_lambda_function.sqs_processor_lambda.function_name
  batch_size       = 10 # Process up to 10 messages at a time
  enabled          = true
}

resource "aws_lambda_permission" "allow_sqs_invocation" {
  statement_id  = "AllowExecutionFromSQS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sqs_processor_lambda.function_name
  principal     = "sqs.amazonaws.com"
  source_arn    = aws_sqs_queue.message_in_queue.arn
}


#### Lambda Function ####


data "archive_file" "lambda_inline_zip" {
  type                    = "zip"
  source_content          = local.lambda_handler_code
  source_content_filename = "handler.py"
  output_path             = "lambda_inline_payload.zip"
}


locals {
  lambda_handler_code = <<-EOT
import json
import os
import boto3

# Initialize the Step Functions client
sfn = boto3.client('stepfunctions')

# SFN ARN should be passed via environment variable for flexibility
SFN_ARN = os.environ.get('SFN_ARN')

def handler(event, context):
    print(f"Received SQS event with {len(event.get('Records', []))} records.")
    
    # Process each message record from the SQS batch
    for record in event['Records']:
        try:
            # 1. Extract the raw message body (the JSON string sent to SQS)
            message_body = record['body']
            print(f"Extracted message body: {message_body}")
            
            # The Step Function requires the raw string as input
            sfn.start_execution(
                stateMachineArn=SFN_ARN,
                # Pass the raw SQS message body as the input payload for the Step Function
                input=message_body
            )
            print(f"Successfully started SFN execution for message: {record['messageId']}")
            
        except Exception as e:
            print(f"ERROR starting SFN execution: {e}")
            # Raising an exception causes Lambda to retry the SQS message
            raise e 
            
    return {"statusCode": 200, "body": "Successfully started SFN executions."}
EOT
}


resource "aws_lambda_function" "sqs_processor_lambda" {
  function_name    = var.lambda_function_name
  tags             = var.default_tags
  filename         = data.archive_file.lambda_inline_zip.output_path
  source_code_hash = data.archive_file.lambda_inline_zip.output_base64sha256
  handler          = "handler.handler"
  runtime          = "python3.9"
  role             = aws_iam_role.lambda_exec_role.arn
  timeout          = 30

  environment {
    variables = {
      SFN_ARN = aws_sfn_state_machine.message_validator.arn
    }
  }
}


#### Step Function (State Machine) ####


resource "aws_iam_role" "sfn_exec_role" {
  name = "${var.step_function_name}_role"
  tags = var.default_tags
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "states.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "sfn_lambda_invoke_policy" {
  name = "${var.step_function_name}_lambda_invoke_policy"
  tags = var.default_tags
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["lambda:InvokeFunction"]
        Resource = [aws_lambda_function.sqs_processor_lambda.arn]
      },
      {
        Effect = "Allow"
        Action = "sqs:SendMessage"
        Resource = [
          aws_sqs_queue.valid_message_queue.arn,
          aws_sqs_queue.invalid_message_queue.arn,
        ]
      },
      {
        Effect = "Allow"
        Action = "sns:Publish"
        Resource = [
          aws_sns_topic.dead_letter_topic.arn
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:log-group:/aws/stepfunctions/${var.step_function_name}:*"
      }
    ]
  })
}

resource "aws_sfn_state_machine" "message_validator" {
  name     = var.step_function_name
  tags     = var.default_tags
  role_arn = aws_iam_role.sfn_exec_role.arn
  definition = templatefile("${path.module}/state_machine.json", {
    aws_region     = var.aws_region
    aws_account_id = data.aws_caller_identity.current.account_id
    # ADDED the required queue name variables
    valid_queue_name       = var.valid_queue_name
    invalid_queue_name     = var.invalid_queue_name
    dead_letter_topic_name = var.dead_letter_topic_name
  })
}


resource "aws_iam_role_policy_attachment" "sfn_policy_attach" {
  role       = aws_iam_role.sfn_exec_role.name
  policy_arn = aws_iam_policy.sfn_lambda_invoke_policy.arn
}



