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
    template_name: str
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

        # Generate the id, creation_date, last_updated, and name
        if creating:
            id = str(uuid.uuid4())
            creation_date = date.today().isoformat()
            updated_at = date.today().isoformat()

            # Create new item
            try:
                template = Template(
                    id=id,
                    creation_date=creation_date,
                    updated_at=updated_at,
                    template_name=body.get(
                        "template_name", "default"
                    ),  # Change 'name' to 'template_name'
                    text=body.get("text", "{{documents}}"),
                    tags=body.get("tags", {}),
                )
                table.put_item(Item=template.model_dump())
            except Exception as e:
                logger.exception(f"Failed to create item: {e}")
                return {"statusCode": 500, "body": f"Failed to create item: {str(e)}"}
        else:
            id = body.get("id", None)
            updated_at = date.today().isoformat()

            # Update existing item
            try:
                table.update_item(
                    Key={"id": id},
                    ExpressionAttributeNames={
                        "#n": "template_name",
                        "#t": "text",
                        "#g": "tags",
                        "#ua": "updated_at",
                    },
                    UpdateExpression="set #ua=:ua, #n=:n, #t=:t, #g=:g",
                    ExpressionAttributeValues={
                        ":ua": updated_at,
                        ":n": body.get("template_name", ""),
                        ":t": body.get("text", ""),
                        ":g": body.get("tags", []),
                    },
                    ReturnValues="UPDATED_NEW",
                )
            except Exception as e:
                logger.exception(f"Failed to update item: {e}")
                return {"statusCode": 500, "body": f"Failed to update item: {str(e)}"}

    except Exception as e:
        logger.exception(f"Exception: {e}")
        return {"statusCode": 500, "body": f"An unexpected error occurred: {str(e)}"}
