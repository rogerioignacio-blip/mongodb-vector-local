#!/bin/bash
set -e

MONGO_URI="mongodb://root:root-password@localhost:27017/rag_demo?authSource=admin&directConnection=true"

echo "Creating collection if needed..."

mongosh "$MONGO_URI" --quiet --eval '
try {
  db.createCollection("documents");
  print("Created collection: documents");
} catch (e) {
  if (e.codeName === "NamespaceExists") {
    print("Collection already exists: documents");
  } else {
    throw e;
  }
}
'

echo "Creating vector index if needed..."

mongosh "$MONGO_URI" --quiet --eval '
const existing = db.runCommand({ listSearchIndexes: "documents" }).cursor.firstBatch;

if (existing.some(idx => idx.name === "vector_index")) {
  print("vector_index already exists.");
} else {
  const result = db.runCommand({
    createSearchIndexes: "documents",
    indexes: [
      {
        name: "vector_index",
        type: "vectorSearch",
        definition: {
          fields: [
            {
              type: "vector",
              path: "embedding",
              numDimensions: 1024,
              similarity: "cosine"
            },
            {
              type: "filter",
              path: "source"
            },
            {
              type: "filter",
              path: "platform"
            }
          ]
        }
      }
    ]
  });

  printjson(result);
}
'

echo "Vector index request completed."
echo "Checking index status..."

mongosh "$MONGO_URI" --quiet --eval '
const indexes = db.runCommand({ listSearchIndexes: "documents" }).cursor.firstBatch;
printjson(indexes);
'
