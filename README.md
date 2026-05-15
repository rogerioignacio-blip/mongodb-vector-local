# MongoDB Community 8.3 + Community Search / mongot + Local Voyage 4 Nano

This project runs a fully local development stack for:

- MongoDB Community Server 8.3.2
- MongoDB Community Search / `mongot`
- Single-node replica set: `rs0`
- MongoDB `$vectorSearch`
- MongoDB `$search`
- Local embeddings using `voyageai/voyage-4-nano`
- Docker Compose

The goal is to run local semantic search and RAG-style experiments without using MongoDB Atlas cloud or Voyage hosted APIs.

---

## Architecture

```text
Local Python app
  |
  | Generates embeddings locally with voyageai/voyage-4-nano
  v
MongoDB on localhost:27017
  |
  | Stores documents + embedding vectors
  v
mongod-vector-local
  |
  | Uses gRPC for Search/Vector Search
  v
mongot-vector-local

Your application connects only to MongoDB:

mongodb://root:root-password@localhost:27017

It does not connect directly to mongot.

Prerequisites

Install:

Docker Desktop
Git
GitHub CLI, optional but useful
MongoDB Shell: mongosh
Python 3.11
Homebrew, recommended on macOS

Check versions:

docker version
git --version
mongosh --version
python3.11 --version

If Python 3.11 is missing on macOS:

brew install python@3.11
Quick start

Clone the repo:

git clone https://github.com/YOUR_USERNAME/mongodb-vector-local.git
cd mongodb-vector-local

Run the bootstrap script:

./scripts/bootstrap.sh

This script does the following:

Creates local secrets
Starts MongoDB
Initializes replica set rs0
Creates mongotUser
Starts mongot
Waits for Search commands to become available
Creates the vector index

Check status:

./scripts/check-status.sh
Set up local Voyage 4 Nano

Create the Python environment:

./scripts/setup-python-voyage.sh

Activate the environment:

cd examples/voyage-nano-local
source .venv/bin/activate

Generate local embeddings and store them in MongoDB:

python embed_store.py

Expected output includes:

Inserted 5 documents.
Embeddings were generated locally and stored in MongoDB.

The first run downloads the model from Hugging Face. After that, the model is cached locally.

Test vector search

From:

cd examples/voyage-nano-local
source .venv/bin/activate

Run:

python query_vector.py

Default query:

How does local MongoDB vector search work?

Expected output:

Top matches:
{'title': 'MongoDB Community Search', ...}
{'title': 'Docker Architecture', ...}
...

You can override the query:

QUERY="What is RAG retrieval?" python query_vector.py

You can also filter by metadata, for example:

PLATFORM_FILTER=aws QUERY="What is generative AI on AWS?" python query_vector.py

This works because the vector index includes platform as a filter field.

Verify stored vectors manually

Connect to MongoDB:

mongosh "mongodb://root:root-password@localhost:27017/rag_demo?authSource=admin&directConnection=true"

Check documents:

db.documents.find(
  { source: "local-demo" },
  {
    title: 1,
    platform: 1,
    embeddingModel: 1,
    embeddingDimensions: 1,
    embeddingPreview: { $slice: ["$embedding", 5] }
  }
).pretty()

You should see:

embeddingModel: "voyageai/voyage-4-nano"
embeddingDimensions: 1024
embeddingPreview: [ ... ]
Verify Search and Vector Search

List Search indexes:

mongosh "mongodb://root:root-password@localhost:27017/rag_demo?authSource=admin&directConnection=true" --eval '
db.runCommand({ listSearchIndexes: "documents" })
'

You should see vector_index.

Create or recreate the vector index manually:

./scripts/create-vector-index.sh

Optional: create a text search index for $search:

./scripts/create-text-search-index.sh
Test $vectorSearch manually

query_vector.py is the easiest way because it generates a query vector locally.

The core query it runs is equivalent to:

db.documents.aggregate([
  {
    $vectorSearch: {
      index: "vector_index",
      path: "embedding",
      queryVector: [...],
      numCandidates: 50,
      limit: 5
    }
  },
  {
    $project: {
      _id: 0,
      title: 1,
      text: 1,
      platform: 1,
      score: { $meta: "vectorSearchScore" }
    }
  }
])
Test $search

First create the text search index:

./scripts/create-text-search-index.sh

Then run:

mongosh "mongodb://root:root-password@localhost:27017/rag_demo?authSource=admin&directConnection=true" --eval '
db.documents.aggregate([
  {
    $search: {
      index: "text_search_index",
      text: {
        query: "MongoDB vector search",
        path: ["title", "text"]
      }
    }
  },
  {
    $project: {
      _id: 0,
      title: 1,
      text: 1,
      score: { $meta: "searchScore" }
    }
  }
])
'
Daily commands

Start everything:

docker compose up -d

Stop everything:

docker compose stop

Check containers:

docker ps

Check stack status:

./scripts/check-status.sh

View MongoDB logs:

docker logs mongod-vector-local --tail 100

View mongot logs:

docker logs mongot-vector-local --tail 100
Reset everything

Warning: this deletes all MongoDB and mongot local data.

docker compose down -v

Then rebuild:

./scripts/bootstrap.sh

Then regenerate embeddings:

./scripts/setup-python-voyage.sh
cd examples/voyage-nano-local
source .venv/bin/activate
python embed_store.py
python query_vector.py
Important files
docker-compose.yml
mongot-config/config.yml
scripts/bootstrap.sh
scripts/setup-secrets.sh
scripts/init-mongodb.sh
scripts/wait-for-search.sh
scripts/create-vector-index.sh
scripts/create-text-search-index.sh
scripts/check-status.sh
scripts/setup-python-voyage.sh
examples/voyage-nano-local/embed_store.py
examples/voyage-nano-local/query_vector.py
examples/voyage-nano-local/requirements.txt
examples/voyage-nano-local/.env.example

Generated local files not committed to Git:

mongod-keyfile/keyfile
mongot-secrets/passwordFile
examples/voyage-nano-local/.env
examples/voyage-nano-local/.venv/
Notes

This setup uses simple local demo credentials:

root / root-password
mongotUser / mongot-password

Do not use these credentials for production.

This project is intended for local development and learning.

