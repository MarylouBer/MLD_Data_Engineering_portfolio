****** IoT Device Processor & Routing Workflow ******

This project deploys a serverless AWS architecture designed to ingest, enrich, and route IoT device data from the nRF Cloud.  It utilizes Terraform for Infrastructure as Code (IaC) and Python for the application logic.
+1


** Architecture Overview

The system follows an event-driven architecture triggered by an SQS queue.

*Trigger: The workflow is initiated when a message is received in the sqs_order_picking queue. 

*Authentication: The Lambda function retrieves a secure API key for nRF Cloud from AWS Secrets Manager. 
+2

*Data Ingestion & Enrichment:
The function calls the device_api_url (nRF Cloud) to get a list of active devices. 
It iterates through devices to fetch the last 10 minutes of message history. 

*Routing Logic:
Real-time Data: All enriched device data is sent to sqs_realtime_box. 
+3
Spoiled Food Alert: If a device reports a temperature < 60, data is routed to sqs_spoiled_food. 
+3
Panic Alert: If a device reports a button press (data: "1"), data is routed to sqs_panic_alert. 
+3


** Project Structure

main.tf: Defines the core resources (SQS queues, Lambda, IAM roles, Log Groups). 
variables.tf: Configuration for queue names, API URLs, and AWS regions. 
outputs.tf: Exports resource ARNs and URLs (e.g., SQS URLs) after deployment. 
order_processing_lambda.py: The Python application logic for fetching and routing data.
provider.tf: Configures the HashiCorp AWS provider and Terraform versions.


** Prerequisites

Terraform: Version ~> 1.2 or higher. 
AWS Provider: Version ~> 4.15.0. 
AWS CLI: Configured with a profile (default in code is saml, but can be overridden). 
Secrets Manager: A secret named bumpy_ride_api_key must exist in AWS Secrets Manager prior to deployment.
