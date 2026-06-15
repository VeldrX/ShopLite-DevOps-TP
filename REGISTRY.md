# Guide Registry et Tags Docker

## Build Docker local

Construire les images localement :

```bash
docker build -t shoplite-api:latest ./api
docker build -t shoplite-frontend:latest ./frontend
```

## Tags Docker simples

Créer des tags versionnés :

```bash
docker tag shoplite-api:latest shoplite-api:v1.0.0
docker tag shoplite-frontend:latest shoplite-frontend:v1.0.0
```

## Lien entre tag Git et tag Docker

Lorsqu'un tag Git (ex: `v1.0.0`) est poussé, le workflow CI/CD construit automatiquement les images Docker avec le tag correspondant et les pousse vers le registry (Docker Hub ou GitHub Container Registry). Voir `.github/workflows/cd.yml`.

## Inspecter une image avec `docker inspect`

```bash
docker inspect shoplite-api:v1.0.0
```

Affiche les métadonnées complètes : couches, variables d'environnement, labels, point d'entrée, etc.

## Historique des images locales

```bash
docker images shoplite-api
```

Montre tous les tags locaux, IDs, tailles et dates de création.

## Comparer image locale et image versionnée

```bash
docker images | grep shoplite-api
```

Permet de vérifier la coexistence des images `latest` et `v1.0.0` et de comparer leurs tailles.

## Rollback

En cas d'incident en production :

```bash
# Récupérer l'ancienne version
docker pull shoplite-api:v1.0.0

# Redéployer avec docker-compose en spécifiant l'image
docker compose -f docker-compose.yml -f docker-compose.staging.yml up -d
```

Les volumes Docker préservent les données PostgreSQL.
