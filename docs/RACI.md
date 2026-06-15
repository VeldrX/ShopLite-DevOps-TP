# RACI - Organisation de l'équipe

## Contexte

ShopLite doit livrer la version v1.1.0 en staging. Une modification casse la route `/api/products`. Le catalogue ne s'affiche plus. L'équipe doit diagnostiquer, sauvegarder, rollbacker sans perte et communiquer.

## Rôles

| Rôle | Responsable |
|------|-------------|
| Product Owner | Définit l'impact métier, valide le service rendu |
| Développeur API | Analyse et corrige le code backend |
| Développeur Frontend | Vérifie l'affichage et confirme l'impact utilisateur |
| DevOps / Release Manager | CI/CD, Docker, tags, déploiement, rollback, smoke tests |
| DBA / Référent données | Sauvegarde PostgreSQL, vérifie l'intégrité des données |
| QA / Testeur | Exécute les tests, valide rouge puis vert |
| Incident Manager | Coordonne la communication, tient la timeline, rédige le rapport |

## Matrice RACI

| Activité | PO | API | Frontend | DevOps | DBA | QA | Incident Manager |
|----------|:--:|:---:|:--------:|:------:|:---:|:--:|:----------------:|
| Créer la version stable Git | I | C | C | **R/A** | I | I | I |
| Mettre en place Docker Compose | I | C | C | **R/A** | - | - | - |
| Configurer la CI/CD | I | C | I | **R/A** | - | C | - |
| Ajouter le test /api/products | I | **R** | - | C | C | **A** | - |
| Sauvegarder PostgreSQL | I | - | - | C | **R/A** | I | I |
| Provoquer l'incident contrôlé | I | **R/A** | I | C | - | C | I |
| Diagnostiquer l'incident | C | **R** | C | **R** | C | C | **A** |
| Décider le rollback | **A** | C | C | **R** | C | C | C |
| Exécuter le rollback | I | I | - | **R/A** | C | I | I |
| Vérifier les données après rollback | I | C | I | - | **R/A** | I | - |
| Valider les tests après rollback | I | C | C | I | - | **R/A** | I |
| Rédiger le rapport d'incident | I | C | I | C | C | C | **R/A** |

### Légende
- **R** : Responsible (réalise l'action)
- **A** : Accountable (valide et porte la responsabilité finale)
- **C** : Consulted (consulté avant/pendant l'action)
- **I** : Informed (tenu informé du résultat)

---

## Timeline de l'incident contrôlé

| Heure | Action | Responsable | Commande / Résultat |
|-------|--------|-------------|---------------------|
| 14:20 | Push sur develop | DevOps | Déclenchement CI/CD |
| 14:22 | Déploiement staging terminé | DevOps | `docker compose up -d` |
| 14:23 | Smoke test échoue | QA (CI) | `curl /api/products` → 500 |
| 14:24 | Alerte incident | Incident Manager | Tableau incident ouvert |
| 14:25 | Analyse logs API | DevOps | `docker compose logs api --tail=50 \| grep error` → `relation "broken_products" does not exist` |
| 14:26 | Identification du changement | API | `git diff HEAD~1 -- api/src/routes/products.js` → table renommée |
| 14:27 | Export des logs | DevOps | `sh scripts/export-logs.sh staging` |
| 14:28 | Vérification image stable | DevOps | `docker image inspect shoplite-api:v1.0.0` → OK |
| 14:28 | Backup PostgreSQL | DBA | `sh scripts/backup.sh staging` → dump créé |
| 14:29 | Décision rollback | PO + Incident Manager | Rollback vers v1.0.0 validé |
| 14:29 | Exécution rollback | DevOps | `sh scripts/rollback.sh staging v1.0.0` |
| 14:30 | Smoke test post-rollback | QA | `sh scripts/smoke-test.sh 8081` → ALL CHECKS PASSED |
| 14:31 | Vérification données | DBA | 3 produits présents (volumes préservés) |
| 14:32 | Communication finale | Incident Manager | Incident résumé et envoyé à l'équipe |

## Analyse des rôles réels (équipe de 2 personnes)

Le TP a été réalisé par une équipe de 2 étudiants. Les rôles ont été répartis ainsi :

| Étudiant | Rôles assumés |
|----------|---------------|
| Étudiant 1 | DevOps / Release Manager, DBA, Incident Manager |
| Étudiant 2 | Développeur API, Développeur Frontend, QA, Product Owner |

### Justification

- **DevOps (Étudiant 1)** : configuration CI/CD, Docker Compose, scripts rollback/backup, registry, tags
- **API/Frontend (Étudiant 2)** : amélioration Dockerfile, routes API, tests, frontend, healthcheck
- **Rôles partagés** : documentation, relecture PR, décisions d'architecture
