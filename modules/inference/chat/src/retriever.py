import os
import json
from aws_lambda_powertools.utilities import parameters
from llama_index.core import VectorStoreIndex
from llama_index.vector_stores.postgres import PGVectorStore
from llama_index.embeddings.bedrock import BedrockEmbedding
from llama_index.core import ServiceContext, set_global_service_context


# TODO: Create another user for the database for the read-only operations
# TODO: Handle the case when the collection is empty or non existent
class Retrieval:
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

        embedding_model = BedrockEmbedding()
        self._index = VectorStoreIndex.from_vector_store(
            vector_store=self._vector_store,
            embed_model=embedding_model,
        )
        self._query_engine = self._index.as_query_engine(similarity_top_k=10)

    def fetch_documents(self, query: str):
        try:
            docs = self._query_engine.query(query)
            
            return [x for x in docs if x[1] > self._relevance_treshold]
        except Exception as e:
            print(f"Error while retrieving documents : {e}")
            raise e
