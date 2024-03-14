from aws_lambda_powertools import Logger, Metrics, Tracer
from aws_lambda_powertools.utilities.typing import LambdaContext
from aws_lambda_powertools.utilities.data_classes import SQSEvent
from aws_lambda_powertools.utilities.data_classes import SQSEvent
import json
import os
import boto3

tracer = Tracer()
logger = Logger()
metrics = Metrics()


@metrics.log_metrics
@logger.inject_lambda_context
@tracer.capture_lambda_handler
def lambda_handler(event: SQSEvent, context: LambdaContext):
    for record in event.records:
        try:
            body = json.loads(record.body)
            bucket = body["s3"]["bucket"]["name"]
            key = body["s3"]["object"]["key"]
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
