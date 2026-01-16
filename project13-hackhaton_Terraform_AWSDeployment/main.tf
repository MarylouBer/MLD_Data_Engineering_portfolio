# This Terraform configuration sets up an AWS serverless workflow where a Lambda function is triggered by messages in an SQS queue (sqs_order_picking). It creates the necessary SQS queues, an IAM role with permissions to access the queues and a Secrets Manager secret, and a CloudWatch log group. The Lambda function polls an external REST API for each active order, processes the data, and sends it to the appropriate SQS queues.
# Note: We decided to simplify and use Lambda for this presentation. For real world, it would be more scalable and cost effective to use AWS IOT service

#### SQS Queues ####

# This block creates the different SQS queues we will use. Each queue serves a specific purpose for message routing based on the data processed by the Lambda function.

resource "aws_sqs_queue" "sqs_order_picking" {
  name = var.sqs_order_picking_queue_name
  tags = var.default_tags
}

resource "aws_sqs_queue" "sqs_realtime_box" {
  name = var.sqs_realtime_box_queue_name
  tags = var.default_tags
}

resource "aws_sqs_queue" "sqs_spoiled_food" {
  name = var.sqs_spoiled_food_queue_name
  tags = var.default_tags
}

resource "aws_sqs_queue" "sqs_accident" {
  name = var.sqs_accident_queue_name
  tags = var.default_tags
}

resource "aws_sqs_queue" "sqs_panic_alert" {
  name = var.sqs_panic_alert_queue_name
  tags = var.default_tags
}


#### Secrets Manager ####

# This data block references an existing secret in AWS Secrets Manager. This existing secret was manually maintained via the AWS Console and holds the API key for nRF Cloud.

data "aws_secretsmanager_secret" "bumpy_ride_api_key" {
  name = var.bumpy_ride_api_key_secret_name
}


#### IAM Role & Policies for Lambda ###

# This resource block defines an IAM role that the Lambda function will assume when it executes. This is a best practice for granting permissions securely.

resource "aws_iam_role" "lambda_exec" {
  name = "${var.lambda_function_name}_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
  tags = var.default_tags
}

# This policy attachment grants the Lambda role the standard permissions needed for logging to CloudWatch.

resource "aws_iam_role_policy_attachment" "lambda_basic_exec" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# This IAM policy grants the Lambda function permissions to interact with our SQS queues, specifically to receive messages (for the trigger queue) and send messages (for the destination queues).

resource "aws_iam_policy" "lambda_sqs_policy" {
  name = "${var.lambda_function_name}_sqs_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = ["sqs:ReceiveMessage", "sqs:SendMessage", "sqs:GetQueueAttributes", "sqs:DeleteMessage"],
      Effect = "Allow",
      Resource = [
        aws_sqs_queue.sqs_order_picking.arn,
        aws_sqs_queue.sqs_realtime_box.arn,
        aws_sqs_queue.sqs_spoiled_food.arn,
        aws_sqs_queue.sqs_panic_alert.arn
      ]
    }]
  })
  tags = var.default_tags
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_sqs_policy.arn
}


# This IAM policy allows the Lambda function to securely retrieve the API token at runtime from AWS Secrets Manager.

resource "aws_iam_policy" "lambda_secrets_policy" {
  name = "${var.lambda_function_name}_secrets_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action   = ["secretsmanager:GetSecretValue"],
      Effect   = "Allow",
      Resource = data.aws_secretsmanager_secret.bumpy_ride_api_key.arn
    }]
  })
  tags = var.default_tags
}

resource "aws_iam_role_policy_attachment" "lambda_secrets_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_secrets_policy.arn
}


#### CloudWatch Log Group ####

# This resource block creates a dedicated CloudWatch log group for the Lambda function's logs, with a specified retention period.

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = var.lambda_log_retention
  tags              = var.default_tags
}


#### Lambda function ####

# This data block uses the `archive_file` data source to package the Python code into a ZIP file, which is then used by the Lambda function.

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "./build/order_processing_lambda.zip"
  # FIX: Change to `source_dir` to package the entire folder
  source_dir = "./lambda_package"
}


# This resource block creates the AWS Lambda function itself, specifying its name, role, runtime, and environment variables.

resource "aws_lambda_function" "order_processing_lambda" {
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_exec.arn
  handler          = "order_processing_lambda.handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  # FIX: Add the filename attribute to link the code zip file
  filename = data.archive_file.lambda_zip.output_path

  environment {
    variables = {
      sqs_order_picking_QUEUE = aws_sqs_queue.sqs_order_picking.url
      sqs_realtime_box_QUEUE  = aws_sqs_queue.sqs_realtime_box.url
      sqs_spoiled_food_QUEUE  = aws_sqs_queue.sqs_spoiled_food.url
      sqs_accident_QUEUE      = aws_sqs_queue.sqs_accident.url
      sqs_panic_alert_QUEUE   = aws_sqs_queue.sqs_panic_alert.url
      SECRET_ARN              = data.aws_secretsmanager_secret.bumpy_ride_api_key.arn
      DEVICE_API_URL          = var.device_api_url
    }
  }
  tags = var.default_tags

  timeout = 60
}

#### Lambda trigger: SQS sqs_order_picking ####

# This resource block sets up the `sqs_order_picking` queue as a trigger for the Lambda function. The function will be invoked as soon as a message arrives in the queue.

resource "aws_lambda_event_source_mapping" "sqs_order_picking_trigger" {
  event_source_arn = aws_sqs_queue.sqs_order_picking.arn
  function_name    = aws_lambda_function.order_processing_lambda.arn
  batch_size       = 1
}

