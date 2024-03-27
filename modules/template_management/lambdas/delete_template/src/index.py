import json
import os
import boto3
from botocore.exceptions import ClientError
from aws_lambda_powertools import Logger, Metrics, Tracer

HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "*",
    "Access-Control-Allow-Headers": "*",
}

# Set up AWS Lambda Powertools
tracer = Tracer()
logger = Logger()
metrics = Metrics()

dynamodb = boto3.resource("dynamodb")


@metrics.log_metrics
@logger.inject_lambda_context
@tracer.capture_lambda_handler
def lambda_handler(event, context):
    # Get the table from environment variables
    table_name = os.environ["DYNAMODB_TABLE"]

    # Get the id from the event
    id = event["pathParameters"]["id"]
    logger.info(f"Deleting item {id} from table {table_name}")
    # Get the table
    table = dynamodb.Table(table_name)

    try:
        # Delete the item from DynamoDB
        response = table.delete_item(Key={"PK": id})

        # Check if item was deleted
        if response["ResponseMetadata"]["HTTPStatusCode"] == 200:
            return {
                "headers": HEADERS,
                "statusCode": 200,
                "body": json.dumps(f"Item {id} deleted successfully"),
            }
        else:
            return {"statusCode": 404, "body": json.dumps(f"Item {id} not found")}
    except ClientError as e:
        logger.exception(e.response["Error"]["Message"])
        return {
            "statusCode": 500,
            "body": "An error occurred",
        }
