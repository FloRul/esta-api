import os
import json
import boto3
from textractor import Textractor
from textractor.data.constants import TextractFeatures
from textractor.data.text_linearization_config import TextLinearizationConfig
from aws_lambda_powertools import Logger, Metrics, Tracer

s3_client = boto3.client("s3")
lambda_client = boto3.client("lambda")
textractor = Textractor(region_name=os.environ["AWS_REGION"])

# Set up AWS Lambda Powertools
tracer = Tracer()
logger = Logger()
metrics = Metrics()


@metrics.log_metrics
@logger.inject_lambda_context
@tracer.capture_lambda_handler
def lambda_handler(event, context):
    bucket = event["bucket"]
    key = event["key"]
    logger.info(f"Invoking textract for {key}")
    try:

        document = textractor.start_document_analysis(
            file_source=f"s3://{bucket}/{key}",
            features=[TextractFeatures.LAYOUT, TextractFeatures.TABLES],
            save_image=False,
            # s3_output_path=f"s3://{os.environ.get("RAW_TEXT_STORAGE")}/{key}/"
        )

        config = TextLinearizationConfig(
            hide_figure_layout=True,
            header_prefix="#",
            title_prefix="##",
            list_layout_prefix="*",
            list_layout_suffix="*",
            layout_element_separator="",
            section_header_prefix="###",
            add_prefixes_and_suffixes_in_text=True,
        )

        text = document.get_text(config=config)
        # write to s3
        s3_client.put_object(
            Bucket=os.environ["RAW_TEXT_STORAGE"],
            Key=f"{key}.txt",
            Body=text,
        )
        logger.info(f"Invoked textract for {key}")
    except Exception as e:
        logger.error(e)
        raise e
    return {"statusCode": 200}
