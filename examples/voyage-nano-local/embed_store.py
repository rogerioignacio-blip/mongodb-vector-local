import os
from datetime import datetime, timezone

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


def choose_device() -> str:
    if torch.backends.mps.is_available():
        return "mps"
    return "cpu"


def load_model() -> SentenceTransformer:
    device = choose_device()

    print(f"Loading model: {MODEL_NAME}")
    print(f"Device: {device}")
    print(f"Embedding dimension: {EMBEDDING_DIM}")

    model = SentenceTransformer(
        MODEL_NAME,
        trust_remote_code=True,
        truncate_dim=EMBEDDING_DIM,
        device=device,
    )

    return model


def embed_documents(model: SentenceTransformer, docs: list[dict]) -> list[list[float]]:
    texts = [doc["text"] for doc in docs]

    print("Generating local document embeddings...")

    if hasattr(model, "encode_document"):
        vectors = model.encode_document(
            texts,
            batch_size=8,
            show_progress_bar=True,
            normalize_embeddings=True,
        )
    else:
        vectors = model.encode(
            texts,
            batch_size=8,
            show_progress_bar=True,
            normalize_embeddings=True,
        )

    return [vector.tolist() for vector in vectors]


def main():
    print("Connecting to MongoDB...")

    client = MongoClient(MONGO_URI)
    db = client[DB_NAME]
    collection = db[COLLECTION_NAME]

    docs = [
        {
            "title": "MongoDB Community Search",
            "text": "MongoDB Community Search uses mongot alongside mongod to support full-text search and vector search locally.",
            "source": "local-demo",
            "platform": "local",
        },
        {
            "title": "Voyage 4 Nano",
            "text": "Voyage 4 Nano is an open-weight embedding model available on Hugging Face for local semantic retrieval.",
            "source": "local-demo",
            "platform": "local",
        },
        {
            "title": "Docker Architecture",
            "text": "This local architecture runs MongoDB Community Server and MongoDB Community Search in separate Docker containers.",
            "source": "local-demo",
            "platform": "local",
        },
        {
            "title": "RAG Retrieval",
            "text": "Retrieval augmented generation uses vector search to find relevant documents before generating an answer.",
            "source": "local-demo",
            "platform": "local",
        },
        {
            "title": "AWS Bedrock Example",
            "text": "AWS Bedrock is a managed service for building generative AI applications using foundation models.",
            "source": "local-demo",
            "platform": "aws",
        },
    ]

    try:
        collection.delete_many({"source": "local-demo"})

        model = load_model()
        vectors = embed_documents(model, docs)

        now = datetime.now(timezone.utc)

        records = []

        for doc, vector in zip(docs, vectors):
            records.append(
                {
                    **doc,
                    "embedding": vector,
                    "embeddingModel": MODEL_NAME,
                    "embeddingDimensions": len(vector),
                    "createdAt": now,
                }
            )

        result = collection.insert_many(records)

        print(f"Inserted {len(result.inserted_ids)} documents.")
        print("Embeddings were generated locally and stored in MongoDB.")

        print("\nStored documents summary:")

        for doc in collection.find(
            {"source": "local-demo"},
            {
                "_id": 0,
                "title": 1,
                "platform": 1,
                "embeddingModel": 1,
                "embeddingDimensions": 1,
            },
        ):
            print(doc)

    finally:
        client.close()


if __name__ == "__main__":
    main()
