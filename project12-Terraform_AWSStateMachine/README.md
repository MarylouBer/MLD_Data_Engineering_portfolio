****** Serverless Message Validation Workflow ******

This repository contains Terraform code to deploy an event-driven, serverless message validation architecture on AWS. It uses SQS for buffering, Lambda as a connector, and AWS Step Functions to route messages based on their validity flag.


** Architecture Overview

The data flow is as follows:

*Ingestion: Messages are sent to an Input SQS Queue.
Trigger: An AWS Lambda function consumes messages from the queue.
Orchestration: The Lambda function extracts the message body and starts an execution of an AWS Step Function.

*Routing (via Step Function):
The State Machine inspects the incoming JSON payload for a valid boolean key.
If valid: true: The message is routed to the sqs_valid_message queue.
If valid: false (or missing): The message is routed to the sqs_invalid_message queue.

*Error Handling: 
Any system errors during the SQS send process are caught and published to an SNS Dead Letter Topic (sfn_dl_topic_errors).


** Architecture & Design Decisions

*Inline Lambda Code
For the sake of simplicity, the Python code for the Lambda function (handler.py) is embedded directly within the main.tf file using Terraform locals.
Why? This removes the need to manage separate .zip artifacts or Python files during the initial deployment. Terraform handles the zipping and hashing automatically.

*State Machine Definition
The Step Function logic is defined in an external template file (state_machine.json). This allows for dynamic injection of AWS resource ARNs (like Queue URLs and Topic ARNs) directly into the Amazon States Language (ASL) definition at deploy time.
The workflow uses a Choice State to determine the path. This visualizes how the workflow splits based on the boolean logic defined in your JSON.


** Project Structure

main.tf: The core resource definitions (SQS, SNS, Lambda, Step Functions, IAM Roles).
variables.tf: Configuration variables for resource names, region, and tags.
provider.tf: AWS Provider configuration and Terraform version constraints.
outputs.tf: Displays critical resource IDs (ARNs, URLs) after deployment.
state_machine.json: (Required) The JSON definition for the Step Function logic.
