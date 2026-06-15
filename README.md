# ShopLite

![CI](https://github.com/VeldrX/ShopLite-DevOps-TP/actions/workflows/ci.yml/badge.svg)
![CD](https://github.com/VeldrX/ShopLite-DevOps-TP/actions/workflows/cd.yml/badge.svg)

Application e-commerce légère (API Node.js + Frontend statique + PostgreSQL) conçue comme support pour un TP DevOps. L'objectif est de mettre en place une chaîne CI/CD complète, des environnements isolés, de la sécurité, des sauvegardes et un rollback maîtrisé.

---

## Architecture

```
[Browser] -> [Nginx Proxy] -> [API Node.js :3000] -> [PostgreSQL :5432]
                           -> [Frontend statique]
```

| Service   | Technologie         | Port exposé |
|-----------|---------------------|-------------|
| Proxy     | nginx:1.27-alpine   | 8080        |
| API       | Node.js 20 / Express | 3000        |
| Frontend  | HTML/CSS/JS statique | -           |
| Database  | PostgreSQL 16 Alpine | 5432        |

---

## Environnements

| Environnement | Port  | Commande de lancement                                  |
|---------------|-------|--------------------------------------------------------|
| Development   | 8080  | `docker compose up -d --build`                         |
| Staging       | 8081  | `docker compose -f docker-compose.yml -f docker-compose.staging.yml --env-file .env.staging up -d` |
| Production    | 8082  | `docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod up -d` |

---

## Prérequis

- Docker & Docker Compose (v2)

---

## Installation et lancement rapide

```bash
# Cloner le projet
git clone https://github.com/VeldrX/ShopLite-DevOps-TP.git
cd ShopLite-DevOps-TP

# Lancer en développement
docker compose up -d --build

# Vérifier le statut
curl http://localhost:8080/api/health
curl http://localhost:8080/api/products
```

---

## Tests

```bash
cd api
npm install
npm test          # Tests unitaires + intégration
npm run test:coverage  # Avec couverture
npm run lint      # ESLint
```

Les tests d'intégration nécessitent PostgreSQL. En CI, un service PostgreSQL est provisionné automatiquement.

---

## CI/CD

### CI (GitHub Actions `.github/workflows/ci.yml`)
Déclenché sur `push` et `pull_request` vers `develop` / `main`.
- Tests sur Node 18.x et 20.x
- Lint + format check
- Tests avec PostgreSQL (couverture)
- Scan Trivy
- Upload artifacts (résultats, coverage)

### CD (GitHub Actions `.github/workflows/cd.yml`)
- **Staging** : déploiement automatique sur push vers `develop`
- **Production** : déploiement automatique sur push de tag `v*.*.*`
- Smoke tests post-déploiement

---

## Docker

```bash
# Construire les images
docker build -t shoplite-api:latest ./api
docker build -t shoplite-frontend:latest ./frontend

# Tagger proprement
docker tag shoplite-api:latest shoplite-api:v1.0.0

# Inspecter une image
docker inspect shoplite-api:v1.0.0
```

Les tags Docker suivent les tags Git. Voir `REGISTRY.md` pour les détails.

---

## Sauvegarde et restauration PostgreSQL

```bash
# Sauvegarder
sh scripts/backup.sh dev

# Tester une restauration
sh scripts/restore-test.sh backups/dev_20260616_120000.sql dev

# Voir les sauvegardes
ls -la backups/
```

Rétention : 7 derniers dump par environnement.

---

## Rollback

```bash
# Exporter les logs avant rollback
sh scripts/export-logs.sh staging

# Effectuer le rollback (vérifie l'image, sauvegarde la DB, préserve les volumes)
sh scripts/rollback.sh staging v1.0.0
```

Le script `rollback.sh` :
1. Exporte les logs courants
2. Identifie la version déployée
3. Vérifie que l'image cible existe
4. Sauvegarde PostgreSQL
5. Arrête la stack (volumes préservés)
6. Redémarre avec l'image taguée
7. Exécute des smoke tests + vérification des données
8. Affiche un résumé d'incident

---

## Observabilité

- **Logs JSON structurés** avec requestId, niveau, durée
- **Sanitisation** des données sensibles dans les query params
- **Rotation** : 3 fichiers de 10 Mo par conteneur
- **Endpoints** : `/api/health` (détaillé), `/api/ready` (readiness)
- **Version** exposée via `APP_VERSION` dans `/api/health`

```bash
# Logs en temps réel
docker compose logs -f api

# Logs avec requestId visible
docker compose logs --tail=50 api | grep error
```

---

## Structure du projet

```
./
├── api/                  # API Node.js Express
│   ├── src/
│   │   ├── routes/       # health.js, products.js
│   │   ├── middleware/    # logger.js
│   │   ├── app.js
│   │   ├── db.js
│   │   └── server.js
│   └── tests/            # Tests Jest + Supertest
├── frontend/             # Frontend statique
│   └── src/              # index.html, app.js, style.css
├── database/             # Scripts SQL
│   ├── init.sql
│   └── migration-v1.1.0.sql
├── infra/nginx/          # Configuration Nginx
├── scripts/              # Scripts d'exploitation
│   ├── backup.sh
│   ├── restore-test.sh
│   ├── rollback.sh
│   ├── export-logs.sh
│   ├── smoke-test.sh
│   └── simulate-incident.sh
├── docs/                 # Documentation
│   ├── ARCHITECTURE.md
│   ├── CHANGELOG.md
│   ├── CONTRIBUTING.md
│   ├── DEPLOY_LOG.md
│   ├── DORA.md
│   ├── ENVIRONMENTS.md
│   └── INCIDENT.md
├── .github/workflows/    # CI / CD pipelines
├── docker-compose.yml    # Stack principale (dev)
├── docker-compose.staging.yml
├── docker-compose.prod.yml
└── REGISTRY.md           # Guide des tags Docker
```

---

## Gestion des risques et sécurité

- **Trivy** : scan des vulnérabilités dans les images Docker (CI)
- **npm audit** : vérification des dépendances
- **Utilisateur non-root** (`USER node`) dans l'image API
- **Logs sanitizés** : secrets, tokens et mots de passe masqués
- **Rotation des logs** évite l'épuisement disque
- **Variables sensibles** via GitHub Secrets (jamais dans le code)

Voir `docs/SECURITY.md` et `docs/GESTION_RISQUE_LIVRAISON.md` pour le détail.

---

## DORA Metrics

| Métrique              | Valeur                             |
|-----------------------|------------------------------------|
| Lead Time             | ~15 min (push → déploiement)       |
| Deployment Frequency  | Plusieurs fois / jour              |
| MTTR                  | < 5 min (rollback script)          |
| Change Failure Rate   | ~10% (incidents contrôlés)         |

Voir `docs/DORA.md` pour le détail.

---

## Documentation connexe

- [Architecture détaillée](docs/ARCHITECTURE.md)
- [Changelog](docs/CHANGELOG.md)
- [Contribution](docs/CONTRIBUTING.md)
- [Gestion des risques](docs/GESTION_RISQUE_LIVRAISON.md)
- [Guide Registry](REGISTRY.md)
- [Sécurité](docs/SECURITY.md)
- [Environnements](docs/ENVIRONMENTS.md)
- [Journal de déploiement](docs/DEPLOY_LOG.md)
- [Template d'incident](docs/INCIDENT.md)
- [Indicateurs DORA](docs/DORA.md)
