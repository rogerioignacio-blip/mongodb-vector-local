#!/bin/bash
set -e

ADMIN_URI="mongodb://root:root-password@localhost:27017/admin?authSource=admin&directConnection=true"
RAG_URI="mongodb://root:root-password@localhost:27017/rag_demo?authSource=admin&directConnection=true"

echo "Docker containers:"
docker ps --filter "name=mongod-vector-local" --filter "name=mongot-vector-local"

echo
echo "MongoDB ping/version/replica set:"
mongosh "$ADMIN_URI" --quiet --eval '
printjson(db.runCommand({ ping: 1 }));
print("Version: " + db.version());
print("Replica set ok: " + rs.status().ok);
'

echo
echo "Search parameters:"
mongosh "$ADMIN_URI" --quiet --eval '
printjson(db.adminCommand({
  getParameter: 1,
  mongotHost: 1,
  searchIndexManagementHostAndPort: 1,
  useGrpcForSearch: 1
}));
'

echo
echo "Search indexes:"
mongosh "$RAG_URI" --quiet --eval '
printjson(db.runCommand({ listSearchIndexes: "documents" }));
'
