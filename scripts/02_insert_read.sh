#!/usr/bin/env bash
# Insertion et lecture de mesures
docker exec -i cassandra1 cqlsh <<'CQL'
USE iot;
INSERT INTO mesures (capteur, date, valeur) VALUES ('capteur_01', '2026-11-14 10:00:00', 21.5);
INSERT INTO mesures (capteur, date, valeur) VALUES ('capteur_01', '2026-11-14 10:05:00', 21.8);
INSERT INTO mesures (capteur, date, valeur) VALUES ('capteur_01', '2026-11-14 10:10:00', 22.1);
INSERT INTO mesures (capteur, date, valeur) VALUES ('capteur_02', '2026-11-14 10:00:00', 18.2);
INSERT INTO mesures (capteur, date, valeur) VALUES ('capteur_02', '2026-11-14 10:05:00', 18.4);
INSERT INTO mesures (capteur, date, valeur) VALUES ('capteur_03', '2026-11-14 10:00:00', 25.0);
INSERT INTO mesures (capteur, date, valeur) VALUES ('capteur_03', '2026-11-14 10:05:00', 25.3);
SELECT * FROM mesures WHERE capteur = 'capteur_01';
SELECT * FROM mesures WHERE capteur = 'capteur_02';
CQL
