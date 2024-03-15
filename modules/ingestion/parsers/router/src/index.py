from aws_lambda_powertools import Logger, Metrics, Tracer
import json
import os
import boto3

tracer = Tracer()
logger = Logger()
metrics = Metrics()


@metrics.log_metrics
@logger.inject_lambda_context
@tracer.capture_lambda_handler
def lambda_handler(event, context):
    records = json.loads(event["Records"][0]["body"])["Records"]
    for record in records:
        try:
            bucket = record["s3"]["bucket"]["name"]
            key = record["s3"]["object"]["key"]
            extension = os.path.splitext(key)[-1]

            logger.info(f"Received record: {key} with extension {extension}")
            lambda_mapping = json.loads(os.environ["LAMBDA_MAPPING"])

            if extension in lambda_mapping:
                lambda_name = lambda_mapping[extension]
                logger.info(f"Invoking {lambda_name} for {key}")
                lambda_client = boto3.client("lambda")
                lambda_client.invoke(
                    FunctionName=lambda_name,
                    InvocationType="Event",
                    Payload=json.dumps(
                        {
                            "bucket": bucket,
                            "key": key,
                        }
                    ),
                )
                logger.info(f"Invoked {lambda_name} for {key}")
            else:
                logger.info(f"Extension {extension} not supported for {key}")
        except Exception as e:
            # TODO: put to dead letter queue
            logger.error(e)
            continue
    return {"statusCode": 200}
