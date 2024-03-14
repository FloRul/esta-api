import json
import os
import boto3
from aws_lambda_powertools.utilities import parameters
from aws_lambda_powertools import Logger, Metrics, Tracer
from aws_lambda_powertools.utilities.data_classes import APIGatewayProxyEventV2
from aws_lambda_powertools.utilities.typing import LambdaContext
from pydantic import BaseModel
from jinja2 import Template, Environment

# Set up AWS Lambda Powertools
tracer = Tracer()
logger = Logger()
metrics = Metrics()

dynamo = boto3.resource("dynamodb")

secret_name = os.environ.get("PGVECTOR_PASS_ARN")
secret = json.loads(parameters.get_secret(name=secret_name))

template_table = dynamo.Table(os.environ.get("TEMPLATE_STORAGE_TABLE_NAME"))


class InferenceChat(BaseModel):
    session_id: str
    message: str
    template_id: str
    collection_id: str


def get_template(template_id: str):
    try:
        # get the template from the database
        return template_table.get_item(Key={"id": template_id})["Item"]["template_text"]
    except Exception as e:
        logger.error(e)
        return None


@metrics.log_metrics
@logger.inject_lambda_context
@tracer.capture_lambda_handler
def lambda_handler(event: APIGatewayProxyEventV2, context: LambdaContext):
    # Parse the body from the event
    body = json.loads(event["body"])
    inference_chat = InferenceChat(**body)

    # Get the template
    template = get_template(inference_chat.template_id)

    if template:
        t = Environment().from_string(template)
        prompt = t.render(
            documents=retriever.fetch_documents(query=inference_chat.message),
            message=inference_chat.message,
        )
        return response
    else:
        return {"error": "Template not found"}
    return []
