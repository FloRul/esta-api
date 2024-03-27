import os
import json
import uuid
from pydantic import BaseModel, ValidationError
from datetime import date
from typing import Dict
from aws_lambda_powertools import Logger, Metrics, Tracer
from aws_lambda_powertools.utilities.data_classes import APIGatewayProxyEventV2
from aws_lambda_powertools.utilities.typing import LambdaContext
from jinja2 import Environment, TemplateSyntaxError
import boto3

# Set up AWS Lambda Powertools
tracer = Tracer()
logger = Logger()
metrics = Metrics()

HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "*",
}


class DateTimeEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, date):
            return o.isoformat()

        return super().default(o)


class Template(BaseModel):
    id: str
    creation_date: str
    updated_at: str
    name: str
    text: str
    tags: Dict[str, str]


dynamodb = boto3.resource("dynamodb")


@metrics.log_metrics
@logger.inject_lambda_context
@tracer.capture_lambda_handler
def lambda_handler(event: APIGatewayProxyEventV2, context: LambdaContext):
    # Get the table from environment variables
    table_name = os.environ["DYNAMODB_TABLE"]

    # Get the table
    table = dynamodb.Table(table_name)
    try:
        # Parse the body from the event
        body = json.loads(event["body"])

        logger.info(f"Received body: {body}")

        creating = body.get("id", None) is None

        # Generate the id, creation_date, last_updated, and name
        if creating:
            id = str(uuid.uuid4())
            creation_date = date.today().isoformat()
            updated_at = date.today().isoformat()
        else:
            id = body.get("id", None)
            updated_at = date.today().isoformat()

        # Validate the Jinja template
        try:
            Environment().parse(body.get("text", ""))
        except TemplateSyntaxError as e:
            logger.exception(f"TemplateSyntaxError: {e}")
            return {"statusCode": 400, "body": f"Invalid Jinja template: {str(e)}"}

        # Check if {{documents}} is in text
        text_stripped = "".join(body.get("text", "").split())
        if "{{documents}}" not in text_stripped:
            logger.exception("The text must contain {{documents}} variable")
            return {
                "statusCode": 400,
                "body": "The text must contain {{documents}} variable",
            }

        # Validate the data using the Template model
        try:
            template = Template(
                id=id,
                creation_date=creation_date,
                updated_at=updated_at,
                **body,
            )
        except ValidationError as e:
            logger.exception(f"ValidationError: {e}")
            return {"statusCode": 400, "body": f"Invalid template data: {str(e)}"}

        # Check if item exists
        try:
            response = table.get_item(Key={"id": id})
        except Exception as e:
            logger.exception(f"Exception: {e}")
            return {"statusCode": 500, "body": f"Failed to get item: {str(e)}"}

        if "Item" in response:
            # Item exists, update it
            try:
                table.update_item(
                    Key={"id": id},
                    UpdateExpression="set creation_date=:d, updated_at=:ua, name=:n, text=:t, tags=:g",
                    ExpressionAttributeValues={
                        ":d": creation_date,
                        ":ua": updated_at,
                        ":n": template.name,
                        ":t": template.text,
                        ":g": template.tags,
                    },
                )
            except Exception as e:
                logger.exception(f"Exception: {e}")
                return {"statusCode": 500, "body": f"Failed to update item: {str(e)}"}
    except Exception as e:
        logger.exception(f"Exception: {e}")
        return {"statusCode": 500, "body": f"An unexpected error occurred: {str(e)}"}
