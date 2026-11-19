#!/usr/bin/env bash
# Sur quels nœuds est stocké un capteur ?
for c in "${@:-capteur_01 capteur_02 capteur_03}"; do
  for s in $c; do
    echo "--- $s ---"
    docker exec cassandra1 nodetool getendpoints iot mesures "$s"
  done
done
