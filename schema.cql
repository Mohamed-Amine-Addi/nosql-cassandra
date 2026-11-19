CREATE KEYSPACE IF NOT EXISTS iot
  WITH replication = {'class': 'NetworkTopologyStrategy', 'dc1': 3};

USE iot;

-- Clé de partition : capteur  | Clustering : date ( plus récent d'abord )
CREATE TABLE IF NOT EXISTS mesures (
  capteur text,
  date    timestamp,
  valeur  double,
  PRIMARY KEY (capteur, date)
) WITH CLUSTERING ORDER BY (date DESC);
