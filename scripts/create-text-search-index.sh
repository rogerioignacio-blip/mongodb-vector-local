#!/bin/bash
set -e

MONGO_URI="mongodb://root:root-password@localhost:27017/rag_demo?authSource=admin&directConnection=true"

echo "Creating text search index if needed..."

mongosh "$MONGO_URI" --quiet --eval '
const existing = db.runCommand({ listSearchIndexes: "documents" }).cursor.firstBatch;

if (existing.some(idx => idx.name === "text_search_index")) {
  print("text_search_index already exists.");
} else {
  const result = db.runCommand({
    createSearchIndexes: "documents",
    indexes: [
      {
        name: "text_search_index",
        definition: {
          mappings: {
            dynamic: false,
            fields: {
              title: {
                type: "string"
              },
              text: {
                type: "string"
              },
              source: {
                type: "stringFacet"
              },
              platform: {
                type: "stringFacet"
              }
            }
          }
        }
      }
    ]
  });

  printjson(result);
}
'

echo "Text search index request completed."
