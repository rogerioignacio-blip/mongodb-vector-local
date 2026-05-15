#!/bin/bash
set -e

cd examples/voyage-nano-local

if ! command -v python3.11 >/dev/null 2>&1; then
  echo "python3.11 was not found."
  echo "Install it first, for example:"
  echo "  brew install python@3.11"
  exit 1
fi

if [ ! -d ".venv" ]; then
  python3.11 -m venv .venv
fi

source .venv/bin/activate

python -m pip install --upgrade pip
pip install -r requirements.txt

if [ ! -f ".env" ]; then
  cp .env.example .env
  echo "Created examples/voyage-nano-local/.env"
else
  echo ".env already exists"
fi

echo "Python Voyage local environment is ready."
echo
echo "Run:"
echo "  cd examples/voyage-nano-local"
echo "  source .venv/bin/activate"
echo "  python embed_store.py"
