#!/bin/bash
set -e

echo "Waiting a few seconds for MongoDB to be ready..."
sleep 5

echo "Testing root authentication..."
docker exec -it mongod-vector-local mongosh \
  -u root \
  -p root-password \
  --authenticationDatabase admin \
  --eval 'db.runCommand({ ping: 1 })'

echo "Initializing replica set if needed..."
docker exec -it mongod-vector-local mongosh \
  -u root \
  -p root-password \
  --authenticationDatabase admin \
  --eval '
try {
  rs.status().ok
  print("Replica set already initialized")
} catch (e) {
  print("Initializing replica set...")
  rs.initiate({
    _id: "rs0",
    members: [
      { _id: 0, host: "mongod-vector-local:27017" }
    ]
  })
}
'

echo "Creating mongotUser if needed..."
docker exec -it mongod-vector-local mongosh \
  -u root \
  -p root-password \
  --authenticationDatabase admin \
  --eval '
db = db.getSiblingDB("admin");

if (db.getUser("mongotUser")) {
  print("mongotUser already exists");
} else {
  db.createUser({
    user: "mongotUser",
    pwd: "mongot-password",
    roles: [
      { role: "searchCoordinator", db: "admin" }
    ]
  });
  print("mongotUser created");
}
'

echo "MongoDB initialization complete."
