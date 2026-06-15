# Changelog

Toutes les modifications notables de ce projet sont documentées ici.

## [v1.1.0] - 2026-06-15

### Ajouté
- Migration non destructive : colonne `category` dans `products` (voir `database/migration-v1.1.0.sql`)
- 3 nouveaux produits : Casque audio, Webcam HD, Hub USB-C
- CD pipeline : déploiement staging (branch develop) et production (tags v*)
- Smoke tests automatisés post-déploiement
- Support multi-environnements (dev, staging, prod)
- Documentation : ARCHITECTURE.md, ENVIRONMENTS.md, DEPLOY_LOG.md

### Modifié
- Healthcheck enrichi : statut DB, version, timestamp
- Logs JSON structurés avec requestId, sanitisation, niveaux
- Rotation des logs Docker (3 x 10 Mo)

## [v1.0.0] - 2026-06-10

### Ajouté
- API Node.js / Express avec routes `/health`, `/products`, `/ready`
- Base PostgreSQL 16 avec table `products` et 3 produits initiaux
- Frontend statique (HTML/CSS/JS)
- Proxy Nginx
- CI pipeline complète : lint, tests (unitaire + intégration), build Docker, Trivy scan
- Docker Compose pour développement
- Tests automatisés : health, products, DB, erreurs
- Scripts de sauvegarde PostgreSQL (`backup.sh`) avec rétention 7 jours
- Script de test de restauration (`restore-test.sh`)
- Script de rollback (`rollback.sh`)
- Guide des tags Docker et registry (`REGISTRY.md`)
- Documentation sécurité (`SECURITY.md`)
- Documentation gestion des risques de livraison (`GESTION_RISQUE_LIVRAISON.md`)
- Configuration des secrets GitHub

## [0.1.0] - 2026-06-01

### Ajouté
- Projet starter ShopLite
- Structure de base API + Frontend + Database
- Configuration Docker minimale
- Test de santé minimal
