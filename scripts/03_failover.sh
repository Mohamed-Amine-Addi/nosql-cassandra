#!/usr/bin/env bash
# Panne d'un nœud : QUORUM réussit, ALL échoue
echo "=== 1. Cluster complet ==="
docker exec cassandra1 nodetool status

echo; echo "=== 2. Arrêt de cassandra3 ==="
docker stop cassandra3
sleep 20
docker exec cassandra1 nodetool status   # cassandra3 doit être DN

echo; echo "=== 3. Lecture en QUORUM (2/3 replicas) -> doit RÉUSSIR ==="
docker exec -i cassandra1 cqlsh <<'CQL'
CONSISTENCY QUORUM;
SELECT * FROM iot.mesures WHERE capteur = 'capteur_01';
CQL

echo; echo "=== 4. Lecture en ALL (3/3 replicas) -> doit ÉCHOUER ==="
docker exec -i cassandra1 cqlsh <<'CQL'
CONSISTENCY ALL;
SELECT * FROM iot.mesures WHERE capteur = 'capteur_01';
CQL

echo; echo "=== 5. Écriture QUORUM pendant la panne -> RÉUSSIT ==="
docker exec -i cassandra1 cqlsh <<'CQL'
CONSISTENCY QUORUM;
INSERT INTO iot.mesures (capteur, date, valeur) VALUES ('capteur_01', '2026-11-14 10:15:00', 22.4);
CQL

echo; echo "=== 6. Redémarrage de cassandra3 ==="
docker start cassandra3
echo "Attendez ~1 min puis : docker exec cassandra1 nodetool status"
