import json
import os
import boto3


dynamo = boto3.resource("dynamodb")


def get_template(template_id: str):
    # get the template from the database
    template = dynamo.Table(os.environ.get("TEMPLATE_STORAGE_TABLE_NAME")).get_item(
        Key={"id": template_id}
    )


def lambda_handler(event, context):
    # get the prompt template
    template_id = event["body"]["template_id"]
    template = get_template(template_id)
