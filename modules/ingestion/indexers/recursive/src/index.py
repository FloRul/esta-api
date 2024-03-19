import os
import json
import boto3

from llama_index.vector_stores.postgres import PGVectorStore
from llama_index.embeddings.bedrock import BedrockEmbedding
from llama_index.core import VectorStoreIndex
from llama_index.core import StorageContext
from llama_index.core.node_parser import LangchainNodeParser
from llama_index.core import SimpleDirectoryReader
from llama_index.core.ingestion import IngestionPipeline

from langchain_text_splitters import RecursiveCharacterTextSplitter

from aws_lambda_powertools.utilities import parameters
from aws_lambda_powertools import Logger, Metrics, Tracer

from botocore.exceptions import ClientError
from botocore.exceptions import NoCredentialsError, BotoCoreError


s3 = boto3.client("s3")

# Set up AWS Lambda Powertools
tracer = Tracer()
logger = Logger()
metrics = Metrics()

secret_name = os.environ.get("PGVECTOR_PASS_ARN")
secret = json.loads(parameters.get_secret(name=secret_name, max_age=3600))


PGVECTOR_HOST = os.environ.get("PGVECTOR_HOST", "localhost")
PGVECTOR_PORT = int(os.environ.get("PGVECTOR_PORT", 5432))
PGVECTOR_DATABASE = os.environ.get("PGVECTOR_DATABASE", "postgres")
PGVECTOR_USER = secret["username"]
PGVECTOR_PASSWORD = secret["password"]

OBJECT_CREATED = "ObjectCreated"


def get_vectorstore(collection_name: str):
    return PGVectorStore.from_params(
        database=PGVECTOR_DATABASE,
        host=PGVECTOR_HOST,
        password=PGVECTOR_PASSWORD,
        port=PGVECTOR_PORT,
        user=PGVECTOR_USER,
        table_name=collection_name,
        embed_dim=1536,
    )


def fetch_file(bucket, key):
    local_filename = f"/tmp/{key.split('/')[-1]}"
    try:
        s3.download_file(bucket, key, local_filename)
    except NoCredentialsError as e:
        print(e)
        raise e
    except BotoCoreError as e:
        print(e)
        raise e
    except ClientError as e:
        print(e)
        raise e
    return local_filename


@metrics.log_metrics
@logger.inject_lambda_context
@tracer.capture_lambda_handler
def lambda_handler(event, context):
    records = json.loads(event["Records"][0]["body"])["Records"]
    for record in records:
        eventName = record["eventName"]
        print(f"eventName: {eventName}")
        try:
            bucket, key = record["s3"]["bucket"]["name"], record["s3"]["object"]["key"]
            logger.info(f"source_bucket: {bucket}, source_key: {key}")

            if eventName.startswith(OBJECT_CREATED):
                local_filename = fetch_file(bucket, key)

                documents = SimpleDirectoryReader(local_filename).load_data()

                logger.info(f"loaded {len(documents)} documents from {local_filename}")

                pipeline = IngestionPipeline(
                    transformations=[
                        LangchainNodeParser(
                            RecursiveCharacterTextSplitter(
                                separators=["/n/n", "/n", ".", " "],
                                chunk_size=512,
                                chunk_overlap=100,
                            ),
                        ),
                        BedrockEmbedding(),
                    ]
                )

                nodes = pipeline.run(documents, num_workers=4)

                vector_store = get_vectorstore(collection_name=bucket)
                storage_context = StorageContext.from_defaults(
                    vector_store=vector_store
                )

                logger.info(f"inserting {len(nodes)} nodes into {bucket} collection.")

                VectorStoreIndex.insert_nodes(
                    nodes=nodes, storage_context=storage_context, show_progress=True
                )

                print(f"insertion complete. {len(nodes)} nodes inserted.")
                return {"status": "success"}
        except Exception as e:
            logger.error(e)
            raise e
