** SQS-SNS Relationship Report Generator

This Python script generates a report that maps AWS SQS queues to their SNS subscriptions and Redrive Policies, and exports the results to an Excel file. It is intended to be run manually in AWS CloudShell, but could be further automated by using Amazon EventBridge Scheduler to regularly trigger an AWS Lambda function that runs this script. Instead of generating a local Excel (.xlsx) file, the script could be modified to create a Google Sheet and save it directly to Google Drive using the Google Drive and Sheets APIs.

Use Case:

- Identify SQS queues with or without SNS subscriptions.
- Check Redrive Policy settings for each queue.
- Export everything into a well-formatted Excel file (`test2sqs_sns_report.xlsx`).

How to Run (in AWS CloudShell):

1. Open AWS CloudShell in the AWS Console.
2. Upload the script
3. Ensure the environment has:
   - `pandas`
   - `openpyxl`
4. Run the script
