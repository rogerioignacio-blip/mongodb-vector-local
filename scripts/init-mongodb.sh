#!/bin/bash
set -e

MONGO_URI="mongodb://root:root-password@localhost:27017/admin?authSource=admin&directConnection=true"

echo "Waiting for MongoDB to accept connections..."

for i in {1..30}; do
  if mongosh "$MONGO_URI" --quiet --eval 'db.runCommand({ ping: 1 }).ok' | grep -q 1; then
    echo "MongoDB is reachable."
    break
  fi

  if [ "$i" -eq 30 ]; then
    echo "MongoDB did not become reachable in time."
    exit 1
  fi

  sleep 2
done

echo "Initializing replica set if needed..."

mongosh "$MONGO_URI" --quiet --eval '
try {
  const status = rs.status();
  if (status.ok === 1) {
    print("Replica set already initialized.");
  }
} catch (e) {
  print("Initializing replica set rs0...");
  rs.initiate({
    _id: "rs0",
    members: [
      { _id: 0, host: "mongod-vector-local:27017" }
    ]
  });
}
'

echo "Waiting for replica set primary..."

for i in {1..30}; do
  if mongosh "$MONGO_URI" --quiet --eval 'rs.status().ok' | grep -q 1; then
    echo "Replica set is healthy."
    break
  fi

  if [ "$i" -eq 30 ]; then
    echo "Replica set did not become healthy in time."
    exit 1
  fi

  sleep 2
done

echo "Creating mongotUser if needed..."

mongosh "$MONGO_URI" --quiet --eval '
db = db.getSiblingDB("admin");

if (db.getUser("mongotUser")) {
  print("mongotUser already exists.");
} else {
  db.createUser({
    user: "mongotUser",
    pwd: "mongot-password",
    roles: [
      { role: "searchCoordinator", db: "admin" }
    ]
  });
  print("mongotUser created.");
}
'

echo "MongoDB initialization complete."
