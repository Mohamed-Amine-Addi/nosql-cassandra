USE iot;

-- 1. Les 10 dernières mesures d'un capteur
SELECT * FROM mesures WHERE capteur = 'capteur_01' LIMIT 10;

-- 2. Les mesures d'une journée (plage de dates)
SELECT * FROM mesures
WHERE capteur = 'capteur_01'
  AND date >= '2026-11-10' AND date < '2026-11-11';

-- 3. Statistiques d'un capteur
SELECT count(*), avg(valeur), min(valeur), max(valeur)
FROM mesures WHERE capteur = 'capteur_05';
