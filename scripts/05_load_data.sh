#!/usr/bin/env bash
# Génère 10 000 mesures et les charge dans Cassandra
set -e
cd "$(dirname "$0")/.."
python generate_data.py || python3 generate_data.py
docker cp mesures.csv cassandra1:/tmp/mesures.csv
docker exec cassandra1 cqlsh -e "COPY iot.mesures (capteur, date, valeur) FROM '/tmp/mesures.csv' WITH HEADER = TRUE;"
echo ">> Nombre de lignes :"
docker exec cassandra1 cqlsh -e "SELECT count(*) FROM iot.mesures;"
