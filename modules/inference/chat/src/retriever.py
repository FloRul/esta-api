import os
import json
from aws_lambda_powertools.utilities import parameters
from typing import Optional

from llama_index.vector_stores.postgres import PGVectorStore
from llama_index.embeddings.bedrock import BedrockEmbedding
from llama_index.core.schema import NodeWithScore
from llama_index.core.vector_stores import VectorStoreQuery

query_mode = "default"
# query_mode = "sparse"
# query_mode = "hybrid"


# TODO: Create another user for the database for the read-only operations
# TODO: Handle the case when the collection is empty or non existent
class Retriever:
    def __init__(
        self,
        collection_name,
        relevance_treshold,
    ):
        secret_name = os.environ.get("PGVECTOR_PASS_ARN")
        secret = json.loads(parameters.get_secret(name=secret_name, max_age=3600))

        self._relevance_treshold = relevance_treshold

        PGVECTOR_HOST = os.environ.get("PGVECTOR_HOST", "localhost")
        PGVECTOR_PORT = int(os.environ.get("PGVECTOR_PORT", 5432))
        PGVECTOR_DATABASE = os.environ.get("PGVECTOR_DATABASE", "postgres")
        PGVECTOR_USER = secret["username"]
        PGVECTOR_PASSWORD = secret["password"]

        self._vector_store = PGVectorStore.from_params(
            database=PGVECTOR_DATABASE,
            host=PGVECTOR_HOST,
            password=PGVECTOR_PASSWORD,
            port=PGVECTOR_PORT,
            user=PGVECTOR_USER,
            table_name=collection_name,
            embed_dim=1536,
        )
        self._embed_model = BedrockEmbedding()

    def fetch_nodes(self, query: str, top_k: int) -> list[NodeWithScore]:
        try:

            query_embedding = self._embed_model.get_query_embedding(query=query)

            vector_store_query = VectorStoreQuery(
                query_embedding=query_embedding,
                similarity_top_k=top_k,
                mode=query_mode,
            )

            query_result = self._vector_store.query(vector_store_query)

            nodes_with_scores = []

            nodes_with_scores = [
                NodeWithScore(node=node, score=score)
                for index, (node, score) in enumerate(
                    zip(query_result.nodes, query_result.similarities or [])
                )
                if score[0] is not None and score >= self._relevance_treshold
            ]

            return nodes_with_scores
        except Exception as e:
            print(f"Error while retrieving documents : {e}")
            raise e
