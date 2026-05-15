#!/bin/bash
set -e

echo "Starting MongoDB Community + mongot local vector search setup..."

./scripts/setup-secrets.sh

echo "Starting mongod..."
docker compose up -d mongod

./scripts/init-mongodb.sh

echo "Starting mongot..."
docker compose up -d mongot

./scripts/wait-for-search.sh
./scripts/create-vector-index.sh

echo
echo "Bootstrap complete."
echo
echo "Next steps:"
echo "1. Set up Python local Voyage 4 Nano example:"
echo "   ./scripts/setup-python-voyage.sh"
echo
echo "2. Generate and store local embeddings:"
echo "   cd examples/voyage-nano-local"
echo "   source .venv/bin/activate"
echo "   python embed_store.py"
echo
echo "3. Test vector search:"
echo "   python query_vector.py"
