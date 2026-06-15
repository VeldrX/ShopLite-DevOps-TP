# Incident

## Template

### Résumé

| Champ       | Valeur |
|-------------|--------|
| Titre       | |
| Date        | |
| Environnement | |
| Impact      | |
| Cause       | |
| Durée       | |
| Détecté par | |

### Timeline

| Heure | Événement |
|-------|-----------|
| HH:MM | |
| HH:MM | |
| HH:MM | |

### Diagnostic

Commandes et outils utilisés pour identifier la cause.

### Correction

Action entreprise pour restaurer le service.

### Prévention

Mesures pour éviter la récidive.

---

## INCIDENT #001 - Table manquante après déploiement

### Résumé

| Champ       | Valeur |
|-------------|--------|
| Titre       | 500 error sur `GET /api/products` - table `broken_products` inexistante |
| Date        | 2026-06-16 |
| Environnement | staging |
| Impact      | L'API retourne une erreur 500 sur `/api/products`. Les autres endpoints (`/api/health`, `/api/ready`) fonctionnent. Le frontend n'affiche plus les produits. |
| Cause       | Déploiement d'une version modifiée de `products.js` qui référence une table `broken_products` au lieu de `products`. |
| Durée       | 8 minutes (14:23 → 14:31) |
| Détecté par | Smoke test automatisé post-déploiement (CI/CD) |

### Timeline

| Heure | Événement |
|-------|-----------|
| 14:20 | Push sur `develop` déclenchant CI/CD |
| 14:22 | Déploiement staging terminé, smoke test automatique lancé |
| 14:23 | Smoke test échoue : `GET /api/products` retourne 500 |
| 14:24 | Alerte : le test automatisé `/api/products` échoue (CI job `deploy-staging` step `smoke test staging`) |
| 14:25 | Diagnostic : `docker compose logs api` montre `relation "broken_products" does not exist` |
| 14:26 | Vérification Git : `git diff HEAD~1 -- api/src/routes/products.js` confirme la table renommée |
| 14:27 | Export des logs : `sh scripts/export-logs.sh staging` |
| 14:28 | Vérification image stable : `docker image inspect shoplite-api:v1.0.0` |
| 14:28 | Backup PostgreSQL : `sh scripts/backup.sh staging` |
| 14:29 | Rollback : `sh scripts/rollback.sh staging v1.0.0` |
| 14:30 | Smoke test post-rollback : PASSED |
| 14:31 | Vérification données : 3 produits présents (volumes préservés) |

### Diagnostic

```bash
# 1. Logs API - l'erreur SQL est visible
docker compose logs api --tail=50 | grep error
# → "relation \"broken_products\" does not exist"

# 2. Vérification avec Git de la modification
git diff HEAD~1 -- api/src/routes/products.js
# → SELECT ... FROM broken_products (vs products)

# 3. Test direct de l'endpoint
curl http://localhost:8081/api/products
# → {"error":"Internal server error"} (500)

# 4. Healthcheck (toujours OK car ne dépend pas de products)
curl http://localhost:8081/api/health
# → {"status":"ok", ...}
```

### Correction

Rollback vers l'image stable `v1.0.0` :

```bash
# Exporter les logs
sh scripts/export-logs.sh staging

# Identifier la version actuelle
docker inspect shoplite_api_staging --format '{{.Config.Image}}'

# Vérifier que l'image stable existe
docker image inspect shoplite-api:v1.0.0

# Backup de la base (inchangée, mais par précaution)
sh scripts/backup.sh staging

# Rollback : arrête la stack (volumes préservés) et redémarre avec v1.0.0
sh scripts/rollback.sh staging v1.0.0

# Vérification
curl http://localhost:8081/api/products
# → {"source":"database","data":[...]}  (200 OK, 3 produits)
```

### Prévention

1. Ajout d'un test automatisé sur `/api/products` dans la CI (déjà présent dans `products.integration.test.js`)
2. Ajout d'un check de nom de table dans la code review (PR template mis à jour)
3. Amélioration du smoke test pour détecter les 500 sur tous les endpoints
4. Pipeline CD : le déploiement staging valide avec smoke test avant promotion en production
5. Conservation des images Docker taguées (`v1.0.0`, `v1.1.0`) pour rollback immédiat

### Communication

> **INCIDENT** : Erreur 500 sur `/api/products` en staging.
> **Cause** : Table `broken_products` inexistante (modification de requête SQL).
> **Action** : Rollback vers `v1.0.0` avec préservation des volumes.
> **Statut** : Résolu (14:31). Smoke test OK, données intactes (3 produits).
