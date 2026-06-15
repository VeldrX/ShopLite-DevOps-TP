# Journal de déploiement

| Version | Date | Auteur | Environnement | Commande | Résultat |
|---|---|---|---|---|---|
| v1.0.0 | 2026-06-15 | Agnija Ilzena | staging | `docker compose --project-name shoplite-staging --env-file .env.staging -f docker-compose.yml -f docker-compose.staging.yml up -d` | ✅ OK |
| v1.1.0 | 2026-06-15 | Agnija Ilzena | staging | `docker compose --project-name shoplite-staging --env-file .env.staging -f docker-compose.yml -f docker-compose.staging.yml up -d --build` | ✅ OK |
