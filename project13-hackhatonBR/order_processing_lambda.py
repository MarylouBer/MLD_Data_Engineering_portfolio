# -*- coding: utf-8 -*-
"""
An AWS Lambda function that is triggered by an event (e.g., SQS, CloudWatch).

The function's primary goal is to provide a near real-time snapshot of all
devices registered in an nRF Cloud account. It performs a multi-stage process:
1. Fetches a summary list of all devices.
2. For each device found, it queries for its message history from the last 10 minutes.
3. It combines the device's summary information with its recent messages.
4. The final enriched list of devices is sent as a single message to an SQS queue.
"""
# --------------------------------------------------------------------------------
# Standard library imports
# --------------------------------------------------------------------------------
import json
import os
import logging
from datetime import datetime, timedelta, timezone

# --------------------------------------------------------------------------------
# Third-party imports
# --------------------------------------------------------------------------------
import boto3
import requests

# --------------------------------------------------------------------------------
# Global Configuration & AWS Service Clients
#
# Clients are initialized globally to be reused across warm Lambda invocations,
# which is a best practice for performance.
# --------------------------------------------------------------------------------
logger = logging.getLogger()
logger.setLevel(logging.INFO)

sqs = boto3.client('sqs')
secrets = boto3.client('secretsmanager')

# --- Environment Variables ---
# These variables must be configured in the Lambda function's environment settings.
sqs_realtime_box_QUEUE = os.environ['sqs_realtime_box_QUEUE']
sqs_spoiled_food_QUEUE = os.environ['sqs_spoiled_food_QUEUE']
sqs_panic_alert_QUEUE = os.environ['sqs_panic_alert_QUEUE']
DEVICE_API_URL = os.environ.get('DEVICE_API_URL')
SECRET_ARN = os.environ.get('SECRET_ARN')


def get_secret():
    """
    PURPOSE:  To retrieve the API token from AWS Secrets Manager.
    CONTRACT: None -> str
    RETURNS:  The API token as a string.
    EFFECTS:  Makes an API call to the AWS Secrets Manager service.
              The function is robust and can handle secrets stored as
              plain text or as a JSON object with any key (e.g., "token", "api_key").
    """
    logger.info("Retrieving API token from Secrets Manager...")
    if not SECRET_ARN:
        raise ValueError("SECRET_ARN environment variable not set. Please configure it in the Lambda settings.")
        
    resp = secrets.get_secret_value(SecretId=SECRET_ARN)
    secret_string = resp['SecretString']
    
    token = None
    try:
        # Attempt to parse the secret as JSON
        secret_json = json.loads(secret_string)
        # If it's a dictionary, get the first value, regardless of the key name.
        if isinstance(secret_json, dict) and secret_json.values():
            token = list(secret_json.values())[0]
            logger.info("Successfully retrieved token from the first value of a JSON secret.")
        else:
            token = secret_string
            logger.info("Secret was valid JSON but not a dictionary with values. Using the raw string.")
    except json.JSONDecodeError:
        # If it's not JSON, assume it's a plain text secret.
        token = secret_string
        logger.info("Successfully retrieved token as plain text.")

    # Log a sanitized version of the token for debugging purposes.
    if token and len(token) > 8:
         logger.info(f"Using token that starts with '{token[:4]}' and ends with '{token[-4:]}'")
    else:
         logger.warning("Retrieved token is very short or empty, which may cause issues.")

    return token


def send_devices_to_queue(queue_url, device_list):
    """
    PURPOSE:  To send the consolidated list of devices and their messages to SQS.
    CONTRACT: str, List[Dict] -> None
    EFFECTS:  Sends one message containing the entire device list to the specified SQS queue.
              Logs the action or any errors that occur.
    """
    if not device_list:
        logger.warning("Device list is empty. Nothing to send to SQS.")
        return

    logger.info(f"Sending {len(device_list)} devices to SQS queue: {queue_url}")
    try:
        message_body = json.dumps({"devices": device_list})
        sqs.send_message(
            QueueUrl=queue_url,
            MessageBody=message_body
        )
        logger.info("Successfully sent device list to SQS.")
    except Exception as e:
        logger.error(f"Failed to send message to SQS: {e}")
        # Re-raise the exception to ensure the Lambda invocation is marked as failed.
        raise e

def send_spoiled_food_to_queue(queue_url, device_list):
    """
    PURPOSE: To send the consolidated list of devices with 'spoiled food'
             temperatures to a specific SQS queue.
    CONTRACT: str, List[Dict] -> None
    EFFECTS: Sends one message containing the entire device list to the
             specified SQS queue.
             Logs the action or any errors that occur.
    """
    if not device_list:
        logger.warning("Device list is empty. Nothing to send to SQS.")
        return

    logger.info(f"Sending {len(device_list)} devices to SQS queue: {queue_url}")
    try:
        message_body = json.dumps({"devices": device_list})
        sqs.send_message(
            QueueUrl=queue_url,
            MessageBody=message_body
        )
        logger.info("Successfully sent device list to SQS.")
    except Exception as e:
        logger.error(f"Failed to send message to SQS: {e}")
        # Re-raise the exception to ensure the Lambda invocation is marked as failed.
        raise e

def send_panic_alert_to_queue(queue_url, device_list):
    """
    PURPOSE: To send the consolidated list of devices with a 'panic' button
             press to a specific SQS queue.
    CONTRACT: str, List[Dict] -> None
    EFFECTS: Sends one message containing the entire device list to the
             specified SQS queue.
             Logs the action or any errors that occur.
    """
    if not device_list:
        logger.warning("Device list is empty. Nothing to send to SQS.")
        return

    logger.info(f"Sending {len(device_list)} devices to SQS queue: {queue_url}")
    try:
        message_body = json.dumps({"devices": device_list})
        sqs.send_message(
            QueueUrl=queue_url,
            MessageBody=message_body
        )
        logger.info("Successfully sent device list to SQS.")
    except Exception as e:
        logger.error(f"Failed to send message to SQS: {e}")
        # Re-raise the exception to ensure the Lambda invocation is marked as failed.
        raise e

# The rest of the handler function remains the same.
def handler(event, context):
    """
    PURPOSE:  Main Lambda handler. Orchestrates fetching device data, enriching it
              with recent messages, and dispatching it to an SQS queue.
    CONTRACT: Dict, Dict -> Dict
    RETURNS:  A dictionary representing an HTTP response, indicating success or failure.
    """
    logger.info("Function execution started.")

    # Fail-fast if essential configuration is missing.
    if not DEVICE_API_URL:
        error_msg = "DEVICE_API_URL environment variable not set or empty. Please configure it."
        logger.error(error_msg)
        return {"statusCode": 500, "body": json.dumps({"status": "FAILED", "reason": error_msg})}

    try:
        # 1. Get the authentication token and prepare headers for API calls.
        api_token = get_secret()
        headers = {"Authorization": f"Bearer {api_token}"}

        # 2. Fetch the initial list of all devices from the nRF Cloud API.
        logger.info(f"Requesting initial device list from {DEVICE_API_URL}...")
        response = requests.get(DEVICE_API_URL, headers=headers, params={"includeState": "true"}, timeout=10)
        response.raise_for_status()
        
        devices_summary = response.json()
        device_items = devices_summary.get("items", [])
        logger.info(f"Successfully fetched summary for {len(device_items)} devices.")

        # 3. For each device, fetch its recent message history to enrich the data.
        enriched_device_list = []
        messages_base_url = DEVICE_API_URL.replace("/devices", "/messages")
        
        # Define time range for messages (last 10 minutes).
        end_time = datetime.now(timezone.utc)
        start_time = end_time - timedelta(minutes=10)
        
        for device_summary in device_items:
            device_id = device_summary.get("id")
            if not device_id:
                logger.warning(f"Skipping a device because it has no ID: {device_summary}")
                continue
            
            try:
                logger.info(f"Fetching last 10 minutes of messages for device {device_id}...")
                message_params = {
                    "deviceId": device_id,
                    "start": start_time.isoformat(),
                    "end": end_time.isoformat()
                }
                
                messages_response = requests.get(messages_base_url, headers=headers, params=message_params, timeout=15)
                messages_response.raise_for_status()
                
                # Combine the device summary with its messages into a single object.
                device_with_messages = device_summary
                device_with_messages['messages'] = messages_response.json().get("items", [])
                enriched_device_list.append(device_with_messages)
                
                logger.info(f"Found {len(device_with_messages['messages'])} messages for device {device_id}.")
                
            except requests.exceptions.RequestException as device_error:
                # Log errors per-device but continue the loop to not fail the entire batch.
                logger.error(f"Failed to fetch messages for device {device_id}: {device_error}")
        
        # Check for devices with a temperature below 60 and send to the 'spoiled food' queue.
        # This will be in addition to sending to the original queue.
        for device in enriched_device_list:
            if 'messages' in device and device['messages']:
                for message in device['messages']:
                    if message.get('message', {}).get('appId') == "TEMP":
                        try:
                            temp_data = float(message['message']['data'])
                            if temp_data < 60:
                                # Send the entire enriched list to the new queue.
                                send_spoiled_food_to_queue(sqs_spoiled_food_QUEUE, enriched_device_list)
                                # Break out of the inner loops once the condition is met for any device.
                                break 
                        except (ValueError, KeyError) as e:
                            logger.error(f"Error parsing temperature data: {e}. Skipping this message.")
                else:
                    continue  # This `continue` is for the inner loop.
                break  # This `break` is for the outer loop.
                
        # Check for a 'BUTTON' press with a data value of '1' and send to the 'panic alert' queue.
        for device in enriched_device_list:
            if 'messages' in device and device['messages']:
                for message in device['messages']:
                    if message.get('message', {}).get('appId') == "BUTTON" and message.get('message', {}).get('data') == "1":
                        send_panic_alert_to_queue(sqs_panic_alert_QUEUE, enriched_device_list)
                        break  # Stop checking this device after the first button press is found.
                else:
                    continue
                break

        # 4. Send the new, enriched list to the destination SQS queue.
        send_devices_to_queue(sqs_realtime_box_QUEUE, enriched_device_list)

        # 5. Return a success response for the Lambda invocation.
        return {
            "statusCode": 200,
            "body": json.dumps({"status": "SUCCESS", "enriched_devices_sent": len(enriched_device_list)})
        }

    except Exception as e:
        # A top-level catch-all for any unexpected errors during execution.
        logger.exception(f"An unexpected error occurred during execution: {e}")
        return {
            "statusCode": 500,
            "body": json.dumps({"status": "FAILED", "reason": str(e)})
        }