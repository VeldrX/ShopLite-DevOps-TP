# Architecture

## Diagramme

```mermaid
graph TB
    subgraph Externe
        DEV[Developpeur]
        GH[GitHub]
        DH[DockerHub / Registry]
    end

    subgraph CI_CD[CI/CD - GitHub Actions]
        CI[CI: test, lint, scan, build]
        CD_STAGING[CD: Deploy staging]
        CD_PROD[CD: Deploy production]
    end

    subgraph Docker[Docker Compose Stack]
        subgraph Reseau[Network: shoplite_net]
            PRXY[Nginx Proxy<br/>:8080]
            API[API Node.js<br/>:3000]
            FE[Frontend Statique]
            DB[(PostgreSQL 16<br/>Volumes persistants)]
        end
    end

    subgraph Environments
        DEV_ENV[dev :8080]
        STG_ENV[staging :8081]
        PRD_ENV[prod :8082]
    end

    subgraph Scripts
        BACKUP[backup.sh<br/>pg_dump + retention]
        ROLLBACK[rollback.sh<br/>image tag + verification]
        SMOKE[smoke-test.sh<br/>health + products + data]
        EXPORT[export-logs.sh]
    end

    DEV -->|git push| GH
    GH -->|push develop| CI
    GH -->|push tag v*| CI
    CI -->|test ok| CD_STAGING
    CI -->|tag v*| CD_PROD
    CD_STAGING -->|docker pull & up| Docker
    CD_PROD -->|docker pull & up| Docker
    Docker --> DH
    DH -->|docker pull v1.0.0| Docker

    PRXY --> API
    PRXY --> FE
    API --> DB

    Docker -->|curl| DEV_ENV
    Docker -->|curl| STG_ENV
    Docker -->|curl| PRD_ENV

    BACKUP --> DB
    ROLLBACK --> Docker
    SMOKE --> API
    EXPORT --> API

    linkStyle default stroke:#666,stroke-width:1px
```

## Flux de déploiement

```
push develop ──> CI (tests, lint, scan) ──> CD staging ──> smoke test
                                                              │
push tag v1.1.0 ──> CI (tests, lint, scan) ──> CD prod ─────┘
                                                              │
                                                    rollback.sh v1.0.0
                                                         (volumes preserved)
```

## Flux de rollback

```
1. Incident détecté (test /api/products échoue)
2. Exporter logs : sh scripts/export-logs.sh staging
3. Identifier version : docker inspect shoplite_api_staging
4. Vérifier image stable : docker image inspect shoplite-api:v1.0.0
5. Backup DB : sh scripts/backup.sh staging
6. Rollback : sh scripts/rollback.sh staging v1.0.0
   - down (sans -v : volumes préservés)
   - up avec l'image taguée
7. Smoke test + vérification données
8. Communication incident
```

## Services

| Service   | Technologie         | Port  | Volumes          |
|-----------|---------------------|-------|------------------|
| Proxy     | nginx:1.27-alpine   | 8080  | -                |
| API       | Node.js 20 / Express| 3000  | -                |
| Frontend  | HTML/CSS/JS statique| -     | -                |
| Database  | PostgreSQL 16 Alpine| 5432  | shoplite_pgdata  |

## Limites de ressources

| Service   | CPU   | Memory |
|-----------|-------|--------|
| API       | 0.50  | 256M   |
| DB        | 0.50  | 256M   |
| Frontend  | 0.25  | 64M    |
| Proxy     | 0.25  | 64M    |
