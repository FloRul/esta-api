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
    template_text: str
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

        # Generate the id, creation_date, last_updated, and template_name
        id = body.get("id", str(uuid.uuid4()))
        creation_date = date.today().isoformat()
        updated_at = date.today().isoformat()
        template_name = "Generated template_name"

        # Validate the Jinja template
        try:
            Environment().parse(body["template_text"])
        except TemplateSyntaxError as e:
            return {"statusCode": 400, "body": f"Invalid Jinja template: {str(e)}"}

        # Check if {{documents}} is in template_text
        template_text_stripped = "".join(body["template_text"].split())
        if "{{documents}}" not in template_text_stripped:
            return {
                "statusCode": 400,
                "body": "The template_text must contain {{documents}} variable",
            }

        body.pop("id", None)
        body.pop("creation_date", None)
        body.pop("updated_at", None)
        body.pop("template_name", None)
        body.pop("tags", None)
        # Validate the data using the Template model
        template = Template(
            id=id,
            creation_date=creation_date,
            updated_at=updated_at,
            template_name=template_name,
            tags=body.get("tags", {}),
            **body,
        )

        # Check if item exists
        response = table.get_item(Key={"id": id})

        if "Item" in response:
            # Item exists, update it
            table.update_item(
                Key={"id": id},
                UpdateExpression="set creation_date=:d, updated_at=:ua, template_name=:n, template_text=:t, tags=:g",
                ExpressionAttributeValues={
                    ":d": creation_date,
                    ":ua": updated_at,
                    ":n": template_name,
                    ":t": template.template_text,
                    ":g": template.tags,
                },
                ReturnValues="UPDATED_NEW",
            )
            operation = "updated"
        else:
            # Item doesn't exist, create it
            table.put_item(Item=template.dict())
            operation = "created"

        return {
            "statusCode": 200,
            "body": json.dumps({"id": id, "operation": operation}, cls=DateTimeEncoder),
        }
    except ValidationError as e:
        logger.exception(f"ValidationError: {e}")
        return {"statusCode": 400, "body": f"Invalid input data: {str(e)}"}
    except Exception as e:
        logger.exception(f"Exception: {e}")
        return {"statusCode": 500, "body": f"An error occurred: {str(e)}"}
