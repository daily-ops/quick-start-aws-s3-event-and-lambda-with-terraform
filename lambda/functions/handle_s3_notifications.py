import json
import os
import logging
import boto3

region_name = os.environ.get('SES_AWS_REGION')
if not region_name:
    raise ValueError("Missing required environment variable SES_AWS_REGION")
from_address = os.environ.get('FROM_ADDRESS')
if not from_address:
    raise ValueError("Missing required environment variable FROM_ADDRESS")
to_address = os.environ.get('TO_ADDRESS')
if not to_address:
    raise ValueError("Missing required environment variable TO_ADDRESS")

# Initialize the S3 client outside of the handler
s3_client = boto3.client('s3')
# Initialize the SES client outside of the handler
ses_client = boto3.client("ses", region_name=region_name)

# Initialize the logger
logger = logging.getLogger()
logger.setLevel("INFO")


def notify_receipt(order_data):

    
    CHARSET = "UTF-8"

    response = ses_client.send_email(
        Destination={
            "ToAddresses": [
                to_address,
            ],
        },
        Message={
            "Body": {
                "Text": {
                    "Charset": CHARSET,
                    "Data": order_data,
                }
            },
            "Subject": {
                "Charset": CHARSET,
                "Data": "New receipt notification",
            },
        },
        Source=from_address,
    )
    logger.info(f"Sendmail response {response}")

def lambda_handler(event, context):
    """
    Main Lambda handler function
    Parameters:
        event: Dict containing the Lambda function event data
        context: Lambda runtime context
    Returns:
        Dict containing status message
    """
    try:

        logger.info(f"Successfully received event {event['Records'][0]['eventName']} from {event['Records'][0]['s3']['bucket']['name']} ")
        bucket = event['Records'][0]['s3']['bucket']['name']
        key = event['Records'][0]['s3']['object']['key']
        s3_response = s3_client.get_object(
            Bucket=bucket,
            Key=key
        )

        # Get the Body object in the S3 get_object() response
        s3_object_body = s3_response.get('Body')
        content_str = s3_object_body.read().decode()

        logger.info(f"Data: {content_str}")
        
        notify_receipt(content_str)
        
        return {
            "statusCode": 200,
            "message": "Event processed successfully"
        }

    except Exception as e:
        logger.error(f"Error processing event: {str(e)}")
        raise