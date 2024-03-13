import json
import os
import boto3
from aws_lambda_powertools.utilities import parameters

dynamo = boto3.resource("dynamodb")


def get_template(template_id: str):
    # get the template from the database
    template = dynamo.Table(os.environ.get("TEMPLATE_STORAGE_TABLE_NAME")).get_item(
        Key={"id": template_id}
    )


def lambda_handler(event, context):
    # get the prompt template
    # template_id = event["body"]["template_id"]
    # template = get_template(template_id)

    # get a secret
    secret_name = os.environ.get("PGVECTOR_PASS_ARN")
    secret = json.loads(parameters.get_secret(name=secret_name))

    return []
