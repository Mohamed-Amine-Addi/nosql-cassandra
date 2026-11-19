// API + site statique du tableau de bord IoT
const express = require('express');
const cassandra = require('cassandra-driver');
const dns = require('dns').promises;
const path = require('path');

const NODES = ['cassandra1', 'cassandra2', 'cassandra3'];
const SIMULATE = process.env.SIMULATE !== 'false'; // simulateur de capteurs actif par défaut
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// Le driver connaît les 3 nœuds : si l'un tombe, les requêtes passent par les autres.
const client = new cassandra.Client({
  contactPoints: NODES,
  localDataCenter: 'dc1',
  pooling: { heartBeatInterval: 5000 },
  queryOptions: { consistency: cassandra.types.consistencies.quorum, prepare: true },
});

// nom du conteneur -> adresse IP (mise à jour à chaque appel, conservée si le nœud est arrêté)
const nameToIp = {};
async function resolveNames() {
  await Promise.all(NODES.map(async (n) => {
    try { nameToIp[n] = (await dns.lookup(n)).address; } catch { /* nœud arrêté : on garde l'ancienne IP */ }
  }));
}

async function init() {
  for (;;) {
    try { await client.connect(); break; }
    catch (e) { console.log('Cassandra pas prête, nouvel essai :', e.message); await sleep(5000); }
  }
  const o = { prepare: false };
  await client.execute("CREATE KEYSPACE IF NOT EXISTS iot WITH replication = {'class': 'NetworkTopologyStrategy', 'dc1': 3}", [], o);
  await client.execute(`CREATE TABLE IF NOT EXISTS iot.mesures (
    capteur text, date timestamp, valeur double, PRIMARY KEY (capteur, date)
  ) WITH CLUSTERING ORDER BY (date DESC)`, [], o);
  console.log('Connecté à Cassandra, schéma prêt.');
  if (SIMULATE) simulate();
}

// Trois capteurs de température qui envoient une mesure toutes les 5 s (écriture en QUORUM)
async function simulate() {
  const temp = { capteur_01: 21.5, capteur_02: 18.2, capteur_03: 25.0 };
  for (;;) {
    for (const id of Object.keys(temp)) {
      temp[id] = +(temp[id] + (Math.random() - 0.5) * 0.6).toFixed(1);
      try {
        await client.execute('INSERT INTO iot.mesures (capteur, date, valeur) VALUES (?, ?, ?)', [id, new Date(), temp[id]]);
      } catch (e) { console.log('Écriture refusée pour', id, ':', e.message); }
    }
    await sleep(5000);
  }
}

const app = express();
app.use(express.static(path.join(__dirname, 'public')));

// État des 3 nœuds vu par le driver
app.get('/api/nodes', async (req, res) => {
  await resolveNames();
  const hosts = [...client.hosts.values()];
  res.json(NODES.map((name) => {
    const h = hosts.find((x) => x.address.split(':')[0] === nameToIp[name]);
    return { name, up: !!h && h.isUp(), datacenter: (h && h.datacenter) || 'dc1', rack: (h && h.rack) || 'rack1' };
  }));
});

// Liste des capteurs avec leur dernière mesure
app.get('/api/sensors', async (req, res) => {
  try {
    const ids = (await client.execute('SELECT DISTINCT capteur FROM iot.mesures')).rows.map((r) => r.capteur).sort();
    res.json(await Promise.all(ids.map(async (id) => {
      const r = (await client.execute('SELECT date, valeur FROM iot.mesures WHERE capteur = ? LIMIT 1', [id])).first();
      return { id, date: r ? r.date : null, valeur: r ? r.valeur : null };
    })));
  } catch (e) { res.status(503).json({ error: e.message }); }
});

// Dernières mesures d'un capteur, de la plus ancienne à la plus récente
app.get('/api/measures', async (req, res) => {
  const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || 40, 1), 200);
  try {
    const rows = (await client.execute('SELECT date, valeur FROM iot.mesures WHERE capteur = ? LIMIT ?',
      [String(req.query.capteur || ''), limit])).rows;
    res.json(rows.map((r) => ({ date: r.date, valeur: r.valeur })).reverse());
  } catch (e) { res.status(503).json({ error: e.message }); }
});

app.listen(3000, () => console.log('Tableau de bord sur http://localhost:3000'));
init();

