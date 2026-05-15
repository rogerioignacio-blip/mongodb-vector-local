# MongoDB Community 8.3 + Community Search / mongot Local Setup

This project runs a local MongoDB Community environment with:

- MongoDB Community Server 8.3.2
- MongoDB Community Search / `mongot`
- Single-node replica set: `rs0`
- Local Vector Search-ready architecture
- Docker Compose

This setup is intended for local development with embeddings, RAG, and `$vectorSearch`.

---

## Prerequisites

Install the following on your laptop:

- Docker Desktop
- Git
- MongoDB Shell (`mongosh`)

Check that Docker is running:

```bash
docker version

Check that mongosh is installed:

mongosh --version
1. Clone this repository
git clone https://github.com/YOUR_USERNAME/mongodb-vector-local.git
cd mongodb-vector-local

Replace YOUR_USERNAME with your GitHub username.

2. Generate local secrets

Do not commit local secret files to GitHub.

Run:

./scripts/setup-secrets.sh

This creates:

mongod-keyfile/keyfile
mongot-secrets/passwordFile

These files are required locally but should stay ignored by Git.

3. Start MongoDB first

Start only the MongoDB container:

docker compose up -d mongod

Check that it is running:

docker ps

Expected container:

mongod-vector-local
4. Initialize MongoDB

Run:

./scripts/init-mongodb.sh

This script does three things:

Tests root authentication
Initializes the single-node replica set rs0
Creates the mongotUser user with the searchCoordinator role
5. Start mongot

After MongoDB is initialized, start mongot:

docker compose up -d mongot

Check both containers:

docker ps

Expected:

mongod-vector-local   Up
mongot-vector-local   Up
6. Check mongot logs

Run:

docker logs mongot-vector-local --tail 100

You want to see lines similar to:

Monitor thread successfully connected
type=REPLICA_SET_PRIMARY
setName='rs0'
mongoDbVersion=8.3.2
Starting gRPC server
Starting health check server
Indexes built and cache initialized

This confirms that mongot successfully connected to mongod.

7. Test MongoDB from your laptop

Run:

mongosh "mongodb://root:root-password@localhost:27017/?authSource=admin&directConnection=true"

Inside mongosh, test:

db.runCommand({ ping: 1 })
db.version()
rs.status().ok

Expected results:

{ ok: 1 }
8.3.2
1

Exit mongosh:

exit
8. Application connection string

Use this connection string from a local Node.js app:

MONGODB_URI=mongodb://root:root-password@localhost:27017/schemaConverter?authSource=admin&directConnection=true

Example .env:

MONGODB_URI=mongodb://root:root-password@localhost:27017/schemaConverter?authSource=admin&directConnection=true
9. Daily usage

Start everything:

docker compose up -d

Stop everything:

docker compose stop

Check running containers:

docker ps

Check all containers, including stopped ones:

docker ps -a

View MongoDB logs:

docker logs mongod-vector-local --tail 100

View mongot logs:

docker logs mongot-vector-local --tail 100
10. Reset everything

Warning: this deletes all local MongoDB and mongot data.

docker compose down -v

Then recreate secrets if needed:

./scripts/setup-secrets.sh

Start again:

docker compose up -d mongod
./scripts/init-mongodb.sh
docker compose up -d mongot
11. Important files
docker-compose.yml
mongot-config/config.yml
scripts/setup-secrets.sh
scripts/init-mongodb.sh
.gitignore
README.md

Generated local files that should not be committed:

mongod-keyfile/keyfile
mongot-secrets/passwordFile
12. Architecture
Local app / mongosh
        |
        v
localhost:27017
        |
        v
mongod-vector-local
MongoDB Community Server 8.3.2
Replica set: rs0
        |
        v
mongot-vector-local
MongoDB Community Search

The application connects only to mongod on localhost:27017.

It does not connect directly to mongot.

mongot is used internally by MongoDB for Search and Vector Search functionality.

