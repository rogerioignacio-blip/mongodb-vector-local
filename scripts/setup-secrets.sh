#!/bin/bash
set -e

echo "Creating local MongoDB/mongot secrets..."

mkdir -p mongod-keyfile
mkdir -p mongot-secrets

if [ ! -f mongod-keyfile/keyfile ]; then
  openssl rand -base64 756 > mongod-keyfile/keyfile
  chmod 400 mongod-keyfile/keyfile
  echo "Created mongod-keyfile/keyfile"
else
  echo "mongod-keyfile/keyfile already exists"
fi

if [ ! -f mongot-secrets/passwordFile ]; then
  echo -n 'mongot-password' > mongot-secrets/passwordFile
  chmod 600 mongot-secrets/passwordFile
  echo "Created mongot-secrets/passwordFile"
else
  echo "mongot-secrets/passwordFile already exists"
fi

echo "Secrets are ready."
