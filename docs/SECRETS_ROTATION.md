# Rotation des secrets

## Périmètre
Ce document décrit la stratégie de rotation des secrets pour le projet ShopLite.

## Secrets gérés

### GitHub Actions Secrets
- `STAGING_DOCKERHUB_USERNAME` / `STAGING_DOCKERHUB_TOKEN`
- `PROD_DOCKERHUB_USERNAME` / `PROD_DOCKERHUB_TOKEN`

### Variables d'application (.env)
- `POSTGRES_PASSWORD` et autres variables de configuration

## Fréquence de rotation

| Secret | Fréquence | Motivations |
|--------|-----------|-------------|
| DockerHub tokens | 6 mois | Recommandation de sécurité |
| Clés API externes | 12 mois ou en cas de compromission | Bonnes pratiques |
| Variables applicatives | En cas de changement d'équipe ou compromission | Maintenance |

## Procédure de rotation

### 1. DockerHub tokens

**Préparation**
1. Générer un nouveau token dans DockerHub (Account Settings > Security > New Access Token)
2. Copier le token temporairement

**Application**
1. Aller dans GitHub > Repository Settings > Secrets and variables > Actions
2. Mettre à jour le secret approprié (`STAGING_DOCKERHUB_TOKEN` ou `PROD_DOCKERHUB_TOKEN`)
3. Cliquer sur "Update secret" et coller le nouveau token
4. Sauvegarder

**Déploiement**
1. Déclencher un déploiement manuel (push sur la branche correspondante)
2. Vérifier que l'application fonctionne avec le nouveau token
3. Révoquer l'ancien token dans DockerHub

### 2. Variables d'application

**Préparation**
1. Générer une nouvelle valeur (ex: mot de passe fort via `openssl rand -base64 32`)
2. Mettre à jour le fichier `.env` local avec la nouvelle valeur
3. Tester en local que l'application fonctionne

**Application en production**
1. Pour la base de données PostgreSQL, appliquer la rotation via script SQL :
   ```sql
   ALTER USER shoplite WITH PASSWORD 'nouveau_mot_de_passe';
   ```
2. Mettre à jour les secrets GitHub si utilisés dans les workflows
3. Redéployer l'application pour prendre en compte la nouvelle variable
4. Vérifier les logs pour s'assurer qu'aucune erreur de connexion n'apparaît

## Récupération en cas d'urgence

### Accès aux secrets
- Seuls les admins de l repository peuvent voir/modifier les secrets GitHub Actions
- Liste des admins : contacter le propriétaire du repository

### Procédure de crise
1. Si un secret est compromis :
   - Générer immédiatement un nouveau token/mot de passe
   - Mettre à jour le secret GitHub dans l'heure
   - Redéployer l'environnement concerné
   - Révoquer l'ancien token partout où il est utilisé
2. Si l'accès GitHub est perdu :
   - Contacter un admin de l'organisation GitHub
   - Utiliser la récupération de compte GitHub si nécessaire

## Vérifications post-rotation

- [ ] Le déploiement s'est déroulé sans erreur
- [ ] Le healthcheck (`/api/health`) retourne 200 OK
- [ ] Les logs ne contiennent pas d'erreurs d'authentification
- [ ] Les fonctionnalités principales sont opérationnelles
- [ ] L'ancien token a été révoqué/desactivé

## Automatisation future

Pour améliorer le processus :
- Mettre en place des reminders calendaires (tous les 6 mois)
- Automatiser la rotation via des scripts dédiés
- Utiliser un vault externe (Hashicorp Vault, AWS Secrets Manager) pour la gestion centralisée