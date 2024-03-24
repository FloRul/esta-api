import json
import os
import boto3
from aws_lambda_powertools import Logger, Metrics, Tracer
from aws_lambda_powertools.utilities.data_classes import APIGatewayProxyEventV2
from pydantic import BaseModel
from jinja2 import Template, Environment

from retriever import Retriever
from history import History

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
    template_id: str
    collection_name: str


def get_template(template_id: str) -> str:
    template = "{{system_prompt}}\n{{ documents }}"
    if template_id:
        response = template_table.get_item(Key={"id": template_id})
        if "Item" in response:
            template = response["Item"]["template_text"]
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
        inference = InferenceChat(**json.loads(event["body"]))

        logger.info(f"loading history for session {inference.session_id}")
        history = History(session_id=inference.session_id)

        # fetch documents
        retriever = Retriever(
            collection_name=inference.collection_name,
            relevance_treshold=os.environ.get("RELEVANCE_TRESHOLD", 0.6),
        )
        docs = retriever.fetch_documents(query=inference.message)
        logger.info(f"found {len(docs)} documents")

        # get the template
        template = get_template(inference.template_id)

        logger.info("fetching chat history...")
        chat_history = history.get(limit=5)
        chat_history.append(
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

        # Render the template
        prompt = Template(template).render(
            system_prompt="",
            documents=" ".join([doc[0].page_content for doc in docs]),
        )

        # raw_response = invoke_model(
        #     system_prompt=system_prompt,
        #     source=source,
        #     messages=chat_history,
        # )

        # response_dict = json.loads(raw_response)

        # # Extract the assistant's messages from the response
        # assistant_messages = [item["text"] for item in response_dict["content"]]
        # # Join all the assistant's messages into a single string
        # response = " ".join(assistant_messages)

        # # save the conversation history
        # history.add(
        #     human_message=query, assistant_message=response, prompt=system_prompt
        # )
        # result = {
        #     "completion": response,
        #     "final_prompt": system_prompt,
        #     "docs": json.dumps(
        #         list(
        #             map(
        #                 lambda x: {
        #                     "content": x[0].page_content,
        #                     "metadata": x[0].metadata,
        #                     "score": x[1],
        #                 },
        #                 docs,
        #             )
        #         )
        #     ),
        # }
        return {
            "statusCode": 200,
            "body": json.dumps(prompt),
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
