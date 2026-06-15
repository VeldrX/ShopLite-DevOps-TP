# Environments

## Local URLs

| Environment | URL | API | Status |
|---|---|---|---|
| Development | http://localhost:8080 | http://localhost:8080/api | `docker compose up -d` |
| Staging | http://localhost:8081 | http://localhost:8081/api | `docker compose --project-name shoplite-staging --env-file .env.staging -f docker-compose.yml -f docker-compose.staging.yml up -d` |
| Production (simulated) | http://localhost:8082 | http://localhost:8082/api | `docker compose --project-name shoplite-prod --env-file .env.prod -f docker-compose.yml -f docker-compose.prod.yml up -d` |

## Ports

| Environment | Port | DB name | Volume |
|---|---|---|---|
| Development | 8080 | shoplite | shoplite_pgdata |
| Staging | 8081 | shoplite_staging | shoplite_pgdata_staging |
| Production | 8082 | shoplite_prod | shoplite_pgdata_prod |

## Health checks

```bash
curl http://localhost:8080/api/health  # dev
curl http://localhost:8081/api/health  # staging
curl http://localhost:8082/api/health  # prod
```

## Teardown

```bash
docker compose --project-name shoplite-dev down
docker compose --project-name shoplite-staging -f docker-compose.yml -f docker-compose.staging.yml down
docker compose --project-name shoplite-prod -f docker-compose.yml -f docker-compose.prod.yml down
```

Add `-v` to also remove DB volumes.
