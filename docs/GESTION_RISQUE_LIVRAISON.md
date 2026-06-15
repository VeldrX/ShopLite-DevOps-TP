# Gestion du risque de livraison

## 1. Comparaison v1.0.0 ↔ v1.1.0

| Domaine | v1.0.0 | v1.1.0 |
|---|---|---|
| CI | Workflow basique | Matrix Node.js (18.x, 20.x), cache npm, services PostgreSQL, lint+format+coverage |
| CD | Workflow basique | Déploiement dev/staging/prod, smoke tests, rollback automatisé |
| Docker Compose | Services api + frontend uniquement | 4 services : db, api, frontend, proxy (nginx) |
| Tests | Aucun | 15 tests unitaires + intégration avec couverture |
| Observabilité | Logs bruts | Logger JSON structuré, healthchecks DB, sanitization des secrets |
| Base de données | 3 produits initiaux | Migration v1.1.0 : colonne `category` + 3 nouveaux produits |
| Documentation | RENDU.md | README.md, REGISTRY.md, ENVIRONMENTS.md, SECRETS_ROTATION.md, DEPLOY_LOG.md |

**Commits entre v1.0.0 et v1.1.0 :**

```
7f34aa1 Feature/hotfix ci cd (#15)
a406661 Fix/prettier logger (#13)
770fec8 Deboug (#12)
ed7e496 feat(observability): étape L - healthchecks, logs JSON, sanitization (#11)
d0a1548 Feature/multi environnements (#10)
59b02e4 Feature/secrets config (#9)
2cf01a2 feat(registry): tags Docker versionnés (#8)
4c37612 Feature/tests quality (#7)
0c2fa38 Feature/ci cd GitHub actions (#6)
0c06532 Feature/docker compose orchestrer (#3)
e60ef28 Feature/docker foundation add C part (#4)
```

**Fichiers modifiés :** 33 fichiers, +1192 lignes / -63 lignes

---

## 2. Redéploiement simple

Lancer la stack complète avec reconstruction des images :

```bash
# Environnement de développement
docker compose --env-file .env up -d --build

# Environnement staging
docker compose --project-name shoplite-staging \
  --env-file .env.staging \
  -f docker-compose.yml -f docker-compose.staging.yml \
  up -d --build

# Environnement production
docker compose --project-name shoplite-prod \
  --env-file .env.prod \
  -f docker-compose.yml -f docker-compose.prod.yml \
  up -d --build
```

### Smoke test après déploiement

```bash
BASE_URL="http://localhost:8080" sh scripts/smoke-test.sh
```

Vérifie :
- `GET /api/health` → 200
- `GET /api/ready` → 200
- `GET /api/products` → 200

---

## 3. Migration SQL non destructive (v1.1.0)

La migration ajoute une colonne `category` et insère 3 nouveaux produits **sans supprimer les produits existants** (`ON CONFLICT DO NOTHING` protège les doublons).

Fichier : `database/migration-v1.1.0.sql`

```sql
ALTER TABLE products ADD COLUMN IF NOT EXISTS category TEXT;

INSERT INTO products (name, description, price_cents, category) VALUES
  ('Casque audio', 'Casque Bluetooth avec réduction de bruit active.', 8990, 'audio'),
  ('Webcam HD', 'Webcam 1080p pour visioconférence.', 4990, 'video'),
  ('Hub USB-C', 'Hub 7-en-1 avec HDMI, USB-A, SD.', 3490, 'accessoires')
ON CONFLICT DO NOTHING;
```

### Exécution

```bash
# Via docker (connexion directe à la base)
docker exec -i shoplite_db psql -U shoplite -d shoplite < database/migration-v1.1.0.sql

# Pour staging
docker exec -i shoplite_db_staging psql -U shoplite_staging -d shoplite_staging < database/migration-v1.1.0.sql

# Pour production
docker exec -i shoplite_db_prod psql -U shoplite_prod -d shoplite_prod < database/migration-v1.1.0.sql
```

---

## 4. Plan de retour arrière (rollback)

Si la version v1.1.0 échoue, revenir à v1.0.0 :

### Étape 1 : Vérifier l'état actuel

```bash
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
docker compose --project-name shoplite-staging ps
BASE_URL="http://localhost:8081" sh scripts/smoke-test.sh
```

### Étape 2 : Restaurer la base de données (annuler la migration)

```bash
# Supprimer les nouveaux produits insérés par la migration
docker exec -i shoplite_db_staging psql -U shoplite_staging -d shoplite_staging -c "
  DELETE FROM products WHERE name IN ('Casque audio', 'Webcam HD', 'Hub USB-C');
"

# Supprimer la colonne category
docker exec -i shoplite_db_staging psql -U shoplite_staging -d shoplite_staging -c "
  ALTER TABLE products DROP COLUMN IF EXISTS category;
"
```

### Étape 3 : Rebasculer le code et redéployer

```bash
# Aller sur le tag stable
git checkout v1.0.0

# Redéployer staging
docker compose --project-name shoplite-staging \
  --env-file .env.staging \
  -f docker-compose.yml -f docker-compose.staging.yml \
  down

docker compose --project-name shoplite-staging \
  --env-file .env.staging \
  -f docker-compose.yml -f docker-compose.staging.yml \
  up -d --build

# Smoke test
sleep 15
BASE_URL="http://localhost:8081" sh scripts/smoke-test.sh
```

### Alternative : script automatisé

```bash
sh scripts/rollback.sh staging v1.0.0
```

Le script `scripts/rollback.sh` exécute automatiquement :
1. `git checkout v1.0.0`
2. `docker compose down`
3. `docker compose up -d --build`
4. Smoke test de validation

### Journal de déploiement

Consulter `docs/DEPLOY_LOG.md` pour l'historique des déploiements.
