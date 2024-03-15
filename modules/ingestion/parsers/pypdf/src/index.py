import PyPDF2
import boto3
from aws_lambda_powertools import Logger, Metrics, Tracer
import os
import io

tracer = Tracer()
logger = Logger()
metrics = Metrics()
s3_client = boto3.client("s3")


@metrics.log_metrics
@logger.inject_lambda_context
@tracer.capture_lambda_handler
def lambda_handler(event, context):
    bucket = event["bucket"]
    key = event["key"]
    logger.info(f"Invoking PyPDF2 for {key}")
    try:
        s3 = boto3.client("s3", region_name=os.environ["AWS_REGION"])
        obj = s3.get_object(Bucket=bucket, Key=key)
        pdf_file_content = obj["Body"].read()

        pdf_file = PyPDF2.PdfFileReader(io.BytesIO(pdf_file_content))
        text = ""
        for page in range(pdf_file.getNumPages()):
            text += pdf_file.getPage(page).extractText()
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
