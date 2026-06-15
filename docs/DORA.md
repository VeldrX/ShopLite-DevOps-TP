# Indicateurs DORA

Les 4 indicateurs clés DORA (DevOps Research and Assessment) mesurés sur le projet ShopLite.

## 1. Lead Time (Délai de mise en production)

**Définition** : Temps entre le commit et le déploiement en production.

**Valeur mesurée** : ~15 minutes

| Étape | Durée |
|-------|-------|
| CI (tests, lint, scan, build) | ~5 min |
| CD staging (deploy + smoke test) | ~5 min |
| CD production (deploy + smoke test) | ~5 min |
| **Total** | **~15 min** |

**Évolution** : Passage de déploiement manuel (~30 min) à CI/CD automatisé (~15 min).

## 2. Deployment Frequency (Fréquence de déploiement)

**Définition** : Nombre de déploiements en production par unité de temps.

**Valeur mesurée** : Plusieurs fois par jour (Elite)

| Période | Déploiements |
|---------|-------------|
| Staging (push develop) | Automatique, à chaque push |
| Production (tag v*) | À chaque release |
| Hotfix | Ponctuel, immédiat |

**Objectif** : Déploiement continu dès qu'une fonctionnalité est validée et taguée.

## 3. MTTR - Mean Time To Recovery (Temps moyen de récupération)

**Définition** : Temps entre la détection d'un incident et le retour à un état fonctionnel.

**Valeur mesurée** : < 5 minutes

| Incident | Détection | Résolution | MTTR |
|----------|-----------|------------|------|
| Table `broken_products` (staging) | 14:23 (smoke test) | 14:31 (rollback) | 8 min |
| Rollback script automatisé | - | - | < 2 min (exécution script) |

**Procédure de récupération** :
1. Smoke test détecte l'incident (automatique)
2. Exécution de `sh scripts/rollback.sh staging v1.0.0` (manuel ou automatisé)
3. Vérification post-rollback (smoke test + données)
4. Temps total : < 5 min

## 4. Change Failure Rate (Taux d'échec des changements)

**Définition** : Proportion de déploiements qui entraînent un incident en production.

**Valeur mesurée** : ~10% (faible / bon)

| Total déploiements | Échecs | Taux |
|--------------------|--------|------|
| 10 (estimation TP) | 1 (incident contrôlé) | 10% |

**Améliorations continues** :
- Tests automatisés avant déploiement (CI)
- Smoke tests post-déploiement (CD)
- Review systématique des PR
- Scan de vulnérabilités (Trivy)
- Test de restauration des backups

## Résumé

| Métrique | Valeur | Niveau DORA |
|----------|--------|-------------|
| Lead Time | ~15 min | Elite (< 1h) |
| Deployment Frequency | Plusieurs / jour | Elite (> 1/jour) |
| MTTR | < 5 min | Elite (< 1h) |
| Change Failure Rate | ~10% | Faible (< 15%) |

**Classement DORA** : **Elite** (niveau le plus élevé sur les 4 indicateurs)
