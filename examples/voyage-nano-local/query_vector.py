import os

import torch
from dotenv import load_dotenv
from pymongo import MongoClient
from sentence_transformers import SentenceTransformer

load_dotenv()

MONGO_URI = os.getenv(
    "MONGO_URI",
    "mongodb://root:root-password@localhost:27017/?authSource=admin&directConnection=true",
)

DB_NAME = os.getenv("DB_NAME", "rag_demo")
COLLECTION_NAME = os.getenv("COLLECTION_NAME", "documents")
MODEL_NAME = os.getenv("MODEL_NAME", "voyageai/voyage-4-nano")
EMBEDDING_DIM = int(os.getenv("EMBEDDING_DIM", "1024"))
VECTOR_INDEX_NAME = os.getenv("VECTOR_INDEX_NAME", "vector_index")


def choose_device() -> str:
    if torch.backends.mps.is_available():
        return "mps"
    return "cpu"


def load_model() -> SentenceTransformer:
    return SentenceTransformer(
        MODEL_NAME,
        trust_remote_code=True,
        truncate_dim=EMBEDDING_DIM,
        device=choose_device(),
    )


def embed_query(model: SentenceTransformer, query: str) -> list[float]:
    if hasattr(model, "encode_query"):
        vector = model.encode_query(
            query,
            normalize_embeddings=True,
        )
    else:
        vector = model.encode(
            query,
            normalize_embeddings=True,
        )

    return vector.tolist()


def main():
    query = os.getenv("QUERY", "How does local MongoDB vector search work?")
    platform_filter = os.getenv("PLATFORM_FILTER")

    print(f"Query: {query}")
    print(f"Loading model: {MODEL_NAME}")

    model = load_model()
    query_vector = embed_query(model, query)

    client = MongoClient(MONGO_URI)
    collection = client[DB_NAME][COLLECTION_NAME]

    vector_stage = {
        "index": VECTOR_INDEX_NAME,
        "path": "embedding",
        "queryVector": query_vector,
        "numCandidates": 50,
        "limit": 5,
    }

    if platform_filter:
        vector_stage["filter"] = {
            "platform": platform_filter
        }

    pipeline = [
        {
            "$vectorSearch": vector_stage
        },
        {
            "$project": {
                "_id": 0,
                "title": 1,
                "text": 1,
                "platform": 1,
                "score": {"$meta": "vectorSearchScore"},
            }
        },
    ]

    print("\nTop matches:")

    for result in collection.aggregate(pipeline):
        print(result)

    client.close()


if __name__ == "__main__":
    main()
