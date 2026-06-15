# ShopLite - Starter TP final DevOps

![CI](https://github.com/VeldrX/ShopLite-DevOps-TP/actions/workflows/ci.yml/badge.svg)
![CD](https://github.com/VeldrX/ShopLite-DevOps-TP/actions/workflows/cd.yml/badge.svg)

ShopLite est un projet de base pour un TP final DevOps.

Les etudiants recoivent uniquement ce socle applicatif :

- API Node.js / Express
- Frontend HTML / CSS / JS
- Script SQL PostgreSQL
- Un test de sante minimal
- Une configuration Docker minimale pour lancer le projet

Le travail du TP consiste a construire progressivement :

- Git propre et strategie de branches
- Ameliorer les Dockerfile API et frontend
- Ameliorer docker-compose dev / staging / prod
- CI/CD GitHub Actions
- tests automatises
- logs propres
- securite container
- backup PostgreSQL
- rollback sans perte de donnees
- documentation professionnelle

## Lancement rapide avec Docker

```bash
docker compose up -d --build
```

Ouvrir :

```text
http://localhost:8080
```

Tester :

```bash
curl http://localhost:8080/api/health
curl http://localhost:8080/api/products
```

Arreter sans supprimer les donnees :

```bash
docker compose down
```

## Lancement hors Docker pour prise en main

```bash
cd api
npm install
npm test
npm start
```

API :

```text
http://localhost:3000/health
http://localhost:3000/products
```

Frontend :

Ouvrir `frontend/src/index.html` dans un navigateur ou le servir avec un serveur statique.

## Important

Le projet contient maintenant le minimum pour tourner avec Docker.
Les etudiants doivent l'ameliorer pendant le TP pour atteindre les exigences finales.

### Execution
Faire relire une PR par un binôme.

## Observabilité

### Endpoints de santé
- **`/api/health`** : Healthcheck détaillé – retourne le statut de l'API et de la base de données, la version de l'application et un timestamp.
- **`/api/ready`** : Readiness probe – retourne 200 OK uniquement si PostgreSQL est joignable. Utilisé par Docker Compose pour waiter que le service est prêt.

Exemples :
```bash
curl http://localhost:8080/api/health
curl http://localhost:8080/api/ready
```

### Logs JSON structurés
Les logs de l'API sont au format JSON. Chaque ligne représente un événement :

```json
{
  "level": "info",
  "requestId": "uuid",
  "method": "GET",
  "path": "/api/products",
  "status": 200,
  "duration_ms": 12,
  "remote_addr": "172.20.0.1",
  "timestamp": "2025-06-15T16:30:45.123Z"
}
```

Niveaux de log :
- `info` : requêtes réussies (status 2xx/3xx)
- `warn` : erreurs client (4xx)
- `error` : erreurs serveur (5xx)

Les paramètres de requête (`query`) sont inclus après sanitisation (les clés sensibles comme `password`, `token` sont remplacées par `[REDACTED]`). Les corps de requête (`body`) ne sont jamais loggés pour protéger les données.

### Rotation des logs
Les logs Docker sont configurés avec rotation automatique :

```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

Cela conserve jusqu'à 3 fichiers de 10 Mo chacun par conteneur.

### Centralisation des logs (production)
En production, les logs devraient être centralisés vers un système comme :
- **ELK Stack** (Elasticsearch, Logstash, Kibana)
- **Grafana Loki** + Promtail
- Solutions SaaS : Datadog, Sentry, etc.

Pour centraliser, on peut changer le driver Docker (`fluentd`, `gelf`, `syslog`) et envoyer les logs vers un aggregator.

### Commandes de diagnostic standard
```bash
# État des conteneurs
docker compose ps

# Logs de l'API (suivi en temps réel)
docker compose logs -f api

# Logs avec limite de lignes
docker compose logs --tail=100 api

# Healthcheck global
curl http://localhost:8080/api/health
curl http://localhost:8080/api/ready

# Inspection détaillée du conteneur API
docker inspect shoplite_api

# Vérification de l'image Docker utilisée
docker images | grep shoplite-api

# Test direct de l'API (hors proxy)
curl http://localhost:3000/health
```

### Tableau de suivi d'incident
Remplir pendant un incident pour le rétrospectif :

| Symptôme | Heure | Cause racine | Commandes utilisées | Résultat / Action |
|----------|-------|--------------|---------------------|-------------------|
| `500 error sur /api/products` | 14:23 | Migration DB manquante | `docker compose logs api`, `docker inspect` | Rollback vers v1.0.0 |
| _À compléter_ | _HH:MM_ | _Description_ | _Outils de diagnostic_ | _Correctif appliqué_ |

### Request ID
Chaque requête HTTP reçoit un `requestId` unique. Celui-ci apparaît dans les logs et permet de tracer une requête à travers les différents services (frontend → API → DB). Utile pour le débogage en équipe.

## Développement local
