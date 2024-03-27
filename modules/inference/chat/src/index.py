import json
import os
import boto3
from aws_lambda_powertools import Logger, Metrics, Tracer
from aws_lambda_powertools.utilities.data_classes import APIGatewayProxyEventV2
from pydantic import BaseModel
from jinja2 import Template, Environment
from typing import Optional
from history import History
from retriever import Retriever
from llama_index.core.schema import NodeWithScore

from retriever import Retriever

HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "*",
}

# Set up AWS Lambda Powertools
tracer = Tracer()
logger = Logger()
metrics = Metrics()

dynamo = boto3.resource("dynamodb")
template_table = dynamo.Table(os.environ.get("TEMPLATE_STORAGE_TABLE_NAME"))


class InferenceChat(BaseModel):
    session_id: str
    message: str
    template_id: Optional[str] = None
    collection_name: str


def invoke_model(
    system_prompt: str,
    messages: list,
):
    try:
        response = boto3.client("bedrock-runtime").invoke_model(
            modelId=os.environ.get(
                "MODEL_ID", "anthropic.claude-3-haiku-20240307-v1:0"
            ),
            accept="application/json",
            contentType="application/json",
            body=json.dumps(
                {
                    "anthropic_version": "bedrock-2023-05-31",
                    "max_tokens": int(os.environ.get("MAX_TOKENS", 300)),
                    "temperature": float(os.environ.get("TEMPERATURE", 0.1)),
                    "system": system_prompt,
                    "messages": messages,
                }
            ),
        )

        res = json.loads(response["body"].read().decode("utf-8-sig"))
        logger.info(f"Model response: {res}")
        return res
    except Exception as e:
        print(f"Model invocation error : {e}")
        raise e


def get_template(template_id: str) -> str:
    template = "{{ documents }}"
    if template_id:
        response = template_table.get_item(Key={"id": template_id})
        if "Item" in response:
            template = response["Item"]["text"]
        else:
            logger.error(
                f"Template with id {template_id} not found, using default template"
            )
    else:
        logger.warning("Template id not provided default template used")
    return template


@metrics.log_metrics
@logger.inject_lambda_context
@tracer.capture_lambda_handler
def lambda_handler(event: APIGatewayProxyEventV2, context):
    logger.info(str(event))
    try:
        inference = InferenceChat(**event["body"])

        # fetch documents
        retriever = Retriever(
            collection_name=inference.collection_name,
            relevance_treshold=os.environ.get("RELEVANCE_TRESHOLD", 0.6),
        )
        nodes_with_score = retriever.fetch_nodes(
            query=inference.message,
            top_k=int(os.environ.get("TOP_K", 5)),
        )
        logger.info(f"retrieval result : {nodes_with_score}")

        # get the template
        template = get_template(inference.template_id)

        # Prepare the chat history
        history = History(session_id=inference.session_id)

        messages = history.get()
        messages.append(
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": inference.message,
                    },
                ],
            }
        )

        logger.info(f"chat history : {messages}")

        # Render the template
        system_prompt = Template(template).render(
            documents="\n".join([node.get_content() for node in nodes_with_score]),
        )

        bedrock_response = invoke_model(
            system_prompt=system_prompt,
            messages=messages,
        )

        # Extract the assistant's messages from the response
        assistant_messages = [item["text"] for item in bedrock_response["content"]]
        # Join all the assistant's messages into a single string
        response = " ".join(assistant_messages)

        # save the conversation history
        history.add(
            human_message=inference.message,
            assistant_message=response,
            prompt=system_prompt,
        )
        return {
            "statusCode": 200,
            "body": json.dumps(
                {
                    "session_id": inference.session_id,
                    "completion": response,
                    "final_prompt": system_prompt,
                    "docs": json.dumps(
                        [
                            {
                                "metadata": n.node.metadata,
                                "content": n.node.text,
                                "score": n.score,
                            }
                            for n in nodes_with_score
                        ],
                        default=lambda o: o.__dict__,
                    ),
                }
            ),
            "headers": HEADERS,
            "isBase64Encoded": False,
        }
    except Exception as e:
        print(e)
        return {
            "statusCode": 500,
            "body": json.dumps(str(e)),
            "headers": HEADERS,
        }


# {
#     "body": {
#         "session_id": "aabbccdd",
#         "message": "quel est l'objectif de l'appel d'offre",
#         "collection_name": "esta-raw-text-storage-dev",
#     }
# }
