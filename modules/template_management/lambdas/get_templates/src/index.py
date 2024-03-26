import os
import boto3
import json
from aws_lambda_powertools import Logger, Metrics, Tracer
from aws_lambda_powertools.utilities.typing import LambdaContext
from aws_lambda_powertools.utilities.data_classes import APIGatewayProxyEventV2

from pydantic import BaseModel, ValidationError
from typing import Dict

# Set up AWS Lambda Powertools
tracer = Tracer()
logger = Logger()
metrics = Metrics()

dynamodb = boto3.resource("dynamodb")


class Template(BaseModel):
    id: str
    creation_date: str
    updated_at: str
    name: str
    text: str
    tags: Dict[str, str]


@metrics.log_metrics
@logger.inject_lambda_context
@tracer.capture_lambda_handler
def lambda_handler(event: APIGatewayProxyEventV2, context: LambdaContext):
    # Get the table from environment variables
    table_name = os.environ["DYNAMODB_TABLE"]

    # Get the table
    table = dynamodb.Table(table_name)

    try:
        # Fetch all items from the table
        response = table.scan()

        return {
            "statusCode": 200,
            "body": json.dumps(
                [Template(**item).model_dump() for item in response["Items"]]
            ),
        }
    except ValidationError as e:
        logger.exception(f"ValidationError: {e}")
        return {"statusCode": 400, "body": f"Invalid data in table: {str(e)}"}
    except Exception as e:
        logger.exception(f"Exception: {e}")
        return {"statusCode": 500, "body": f"An error occurred: {str(e)}"}
