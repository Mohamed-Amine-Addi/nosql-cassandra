# Réplication Cassandra pour capteurs IoT

Plateforme de stockage de mesures de capteurs, tolérante à la panne d'un nœud.

## Architecture

```
            réseau Docker iot-net
  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
  │ cassandra1   │ │ cassandra2   │ │ cassandra3   │
  │ (seed, 9042) │ │              │ │              │
  │ heap 512M    │ │ heap 512M    │ │ heap 512M    │
  └──────┬───────┘ └──────┬───────┘ └──────┬───────┘
         └──── gossip / réplication RF=3 ───┘
```

- Cluster `IoTCluster`, datacenter `dc1`, rack `rack1`
- Keyspace `iot` : NetworkTopologyStrategy, `dc1: 3` (chaque donnée sur les 3 nœuds)
- Table `mesures(capteur, date, valeur)`, clé de partition `capteur`, clustering `date DESC`
- Mémoire : `MAX_HEAP_SIZE=512M`, `HEAP_NEWSIZE=128M`, limite conteneur 1,5 Go (≈ 6 Go RAM libre conseillés avec Docker)

## Prérequis
Docker + Docker Compose v2.

## Démonstration

| Étape | Commande |
|---|---|
| Déployer + `nodetool status` + schéma | `./scripts/01_deploy.sh` |
| Insérer et lire des mesures | `./scripts/02_insert_read.sh` |
| Panne : QUORUM OK / ALL échoue | `./scripts/03_failover.sh` |
| Nœuds hébergeant un capteur | `./scripts/04_endpoints.sh capteur_01` |
| Nettoyage | `./scripts/99_cleanup.sh` |

Le démarrage est séquentiel (healthchecks) : comptez 3 à 5 minutes.

## Site web (tableau de bord)
Après `./scripts/01_deploy.sh`, ouvrez **http://localhost:3000** :
- liste des capteurs avec leur dernière mesure (clic = changer de capteur) ;
- graphique de température des 40 dernières mesures ;
- état des 3 nœuds Cassandra, rafraîchi toutes les 3 s ;
- bannière d'alerte rouge dès qu'un nœud tombe (essayez `./scripts/03_failover.sh`).

Le service `web` (Node.js, dossier `web/`) lit Cassandra en QUORUM et simule 3 capteurs qui écrivent une mesure toutes les 5 s (désactivable avec `SIMULATE=false`).

## Explication théorique
RF = 3 donc QUORUM = ⌊3/2⌋ + 1 = 2 réplicas.
- Un nœud arrêté : 2 réplicas restent, donc **QUORUM réussit**.
- ALL exige 3 réplicas : **ALL échoue** (`NoHostAvailable` / `Unavailable`).
- Les écritures faites pendant la panne sont rattrapées au retour du nœud (hinted handoff / repair).

## Commandes manuelles utiles
```bash
docker exec -it cassandra1 nodetool status
docker exec -it cassandra1 cqlsh
docker exec cassandra1 nodetool getendpoints iot mesures capteur_01
```
