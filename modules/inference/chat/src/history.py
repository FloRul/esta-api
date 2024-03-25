import time
import os
import boto3
from botocore.exceptions import ClientError
from boto3.dynamodb.conditions import Key


class History:
    def __init__(self, session_id: str):
        self._session_id = session_id
        self._dynamodb = boto3.resource("dynamodb")

    def get(self, limit: int = 10):
        result = []
        try:
            table = self._dynamodb.Table(os.getenv("HISTORY_STORAGE_TABLE_NAME"))
            response = table.query(
                KeyConditionExpression=Key("PK").eq(self._session_id),
                ScanIndexForward=False,
                Limit=limit,
            )

            for x in response["Items"]:
                result.append(
                    {
                        "role": "user",
                        "content": [
                            {
                                "type": "text",
                                "text": x["HumanMessage"],
                            },
                        ],
                    }
                )
                result.append(
                    {
                        "role": "assistant",
                        "content": [
                            {
                                "type": "text",
                                "text": x["AssistantMessage"],
                            },
                        ],
                    }
                )
        except ClientError as e:
            print(f"An error occurred: {e}")
        return result

    def add(self, human_message: str, assistant_message: str, prompt: str):
        try:
            table = self._dynamodb.Table(os.environ.get("HISTORY_STORAGE_TABLE_NAME"))  # type: ignore
            item = {
                "PK": self._session_id,
                "HumanMessage": human_message,
                "AssistantMessage": assistant_message,
                "SK": str(time.time()),
                "Prompt": prompt,
            }
            table.put_item(Item=item)
            return item
        except ClientError as e:
            print(e.response["Error"]["Message"])
            raise e
