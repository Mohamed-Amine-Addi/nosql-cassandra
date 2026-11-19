import csv, random
from datetime import datetime, timedelta, timezone

random.seed(42)
NB_CAPTEURS, NB_MESURES = 50, 200
# (moyenne, écart-type) : température, humidité, pression
TYPES = [(25, 3), (55, 8), (1010, 5)]
debut = datetime(2026, 11, 10, 0, 0, tzinfo=timezone.utc)

with open("mesures.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["capteur", "date", "valeur"])
    for i in range(1, NB_CAPTEURS + 1):
        moy, ecart = TYPES[i % 3]
        base = random.gauss(moy, ecart / 2)
        for k in range(NB_MESURES):
            t = debut + timedelta(minutes=50 * k)
            v = round(random.gauss(base, ecart), 2)
            w.writerow([f"capteur_{i:02d}", t.strftime("%Y-%m-%d %H:%M:%S+0000"), v])

print(f"mesures.csv généré : {NB_CAPTEURS * NB_MESURES} lignes")
