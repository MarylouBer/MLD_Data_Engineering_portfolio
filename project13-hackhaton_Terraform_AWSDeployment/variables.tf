# This file defines all the input variables for the Terraform configuration.
# Variables allow you to customize and reuse your configuration without
# modifying the source code.
# -----------------------------------------------------------------------------

# The AWS region where all of the infrastructure will be deployed.
variable "aws_region" {
  type        = string
  default     = "eu-central-1"
  description = "The AWS region where resources will be created."
}

# The name for the main Lambda function.
variable "lambda_function_name" {
  type        = string
  default     = "iot-device-processor"
  description = "The name of the main Lambda function that processes IoT device data."
}

# The number of days to retain CloudWatch logs for the Lambda function.
variable "lambda_log_retention" {
  type        = number
  default     = 14 # days
  description = "The number of days to retain logs for the Lambda function in CloudWatch."
}

# The name of the SQS queue for order picking messages.
variable "sqs_order_picking_queue_name" {
  type        = string
  default     = "sqs_order_picking"
  description = "The name of the SQS queue for order picking messages."
}

# The name of the SQS queue for panic alert messages, triggered by a button press.
variable "sqs_panic_alert_queue_name" {
  type        = string
  default     = "sqs_panic_alert"
  description = "The name of the SQS queue for panic alerts triggered by a device button press."
}

# The name of the SQS queue for real-time device messages.
variable "sqs_realtime_box_queue_name" {
  type        = string
  default     = "sqs_realtime_box"
  description = "The name of the main SQS queue for real-time device data snapshots."
}

# The name of the SQS queue for spoiled food alerts, triggered by temperature drops.
variable "sqs_spoiled_food_queue_name" {
  type        = string
  default     = "sqs_spoiled_food"
  description = "The name of the SQS queue for alerts when a device reports a temperature indicating spoiled food."
}

# The name of the SQS queue for accident alerts.
variable "sqs_accident_queue_name" {
  type        = string
  default     = "sqs_accident"
  description = "The name of the SQS queue for alerts related to a device accident or unexpected event."
}

# The URL for the nRF Cloud API to fetch device data.
variable "device_api_url" {
  type        = string
  default     = "https://api.nrfcloud.com/v1/devices"
  description = "The base URL for the nRF Cloud API to fetch device information."
}

# The name of the secret in AWS Secrets Manager that holds the nRF Cloud API key.
variable "bumpy_ride_api_key_secret_name" {
  type        = string
  default     = "bumpy_ride_api_key"
  description = "The name of the secret in AWS Secrets Manager that contains the API key for nRF Cloud."
}

# A map of default tags to be applied to all resources for identification and cost tracking.
variable "default_tags" {
  type = map(string)
  default = {
    dh_platform = "platform"
    dh_tribe    = "developer_platform"
    dh_app      = "gmlp-hack-bumpyride"
    dh_squad    = "dhse-gmlp-hackathon"
  }
  description = "A map of default tags to apply to all resources for easy identification and cost allocation."
}
