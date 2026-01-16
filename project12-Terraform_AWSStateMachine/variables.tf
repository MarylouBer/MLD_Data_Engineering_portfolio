variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "eu-central-1"
}

variable "lambda_function_name" {
  description = "Name for the AWS Lambda function."
  type        = string
  default     = "POC_TestStep"
}

variable "step_function_name" {
  description = "Name for the AWS Step Function State Machine."
  type        = string
  default     = "MessageValidationSF"
}


variable "input_queue_name" {
  description = "Name for the SQS queue that inputs messages."
  type        = string
  default     = "sqs_input_message"
}

variable "valid_queue_name" {
  description = "Name for the SQS queue for valid messages."
  type        = string
  default     = "sqs_valid_message"
}

variable "invalid_queue_name" {
  description = "Name for the SQS queue for invalid messages."
  type        = string
  default     = "sqs_invalid_message"
}

variable "dead_letter_topic_name" {
  description = "Name for the SNS topic used as the Dead-Letter Topic for SFN errors."
  type        = string
  default     = "sfn_dl_topic_errors"
}

variable "default_tags" {
  type = map(string)
  default = {
    dh_platform = "finance_systems"
    dh_tribe    = "finance_systems"
    dh_app      = "POC_SFN_Orders"
    dh_cc_id    = "1001010035"
    dh_squad    = "fs-sap"
  }
  description = "A map of default tags to apply to all resources for easy identification and cost allocation."
}
