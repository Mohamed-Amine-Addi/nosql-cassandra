#!/usr/bin/env bash
# Déploie le cluster, attend les 3 nœuds, crée le schéma
set -e
cd "$(dirname "$0")/.."
docker compose up -d
echo ">> Attente des 3 nœuds (UN)..."
until [ "$(docker exec cassandra1 nodetool status 2>/dev/null | grep -c '^UN')" -eq 3 ]; do
  sleep 10; echo "   ..."
done
docker exec cassandra1 nodetool status
docker exec -i cassandra1 cqlsh < schema.cql
echo ">> Schéma créé."
docker exec cassandra1 cqlsh -e "DESCRIBE KEYSPACE iot;"

