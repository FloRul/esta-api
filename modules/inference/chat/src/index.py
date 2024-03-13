import json
import os
import boto3
from aws_lambda_powertools.utilities import parameters
from aws_lambda_powertools import Logger, Metrics, Tracer
from aws_lambda_powertools.utilities.data_classes import APIGatewayProxyEventV2
from aws_lambda_powertools.utilities.typing import LambdaContext


# Set up AWS Lambda Powertools
tracer = Tracer()
logger = Logger()
metrics = Metrics()

dynamo = boto3.resource("dynamodb")


def get_template(template_id: str):
    # get the template from the database
    template = dynamo.Table(os.environ.get("TEMPLATE_STORAGE_TABLE_NAME")).get_item(
        Key={"id": template_id}
    )


@metrics.log_metrics
@logger.inject_lambda_context
@tracer.capture_lambda_handler
def lambda_handler(event, context):
    # Parse the body from the event
    body = json.loads(event["body"])
    
    secret_name = os.environ.get("PGVECTOR_PASS_ARN")
    secret = json.loads(parameters.get_secret(name=secret_name))

    return []
