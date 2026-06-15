# Sécurité DevSecOps

## Lecture du Dockerfile

| Élément | Valeur |
|---|---|
| Image de base | `node:20-alpine` |
| Port exposé | `3000` |
| Commande de démarrage | `node src/server.js` |
| Utilisateur | `node` (non-root) |
| Stage multi-étapes | oui (builder + runtime) |

## Contrôle des ports exposés

| Port | Service | Exposition |
|---|---|---|
| 3000 | API Node.js | Interne uniquement (via nginx) |
| 80 | Nginx proxy | Interne uniquement |
| 8080 | Proxy dev | Local uniquement |
| 8081 | Proxy staging | Local uniquement |
| 8082 | Proxy prod simulée | Local uniquement |
| 5432 | PostgreSQL | Interne uniquement (aucun port host) |

## Vérification du fichier .env.example

| Variable | Présente dans .env.example | Valeur d'exemple |
|---|---|---|
| `NODE_ENV` | ✅ | `development` |
| `API_PORT` | ✅ | `3000` |
| `HTTP_PORT` | ✅ | `8080` |
| `APP_VERSION` | ✅ | `starter` |
| `POSTGRES_DB` | ✅ | `shoplite` |
| `POSTGRES_USER` | ✅ | `shoplite` |
| `POSTGRES_PASSWORD` | ✅ | `shoplite_password` |
| `DATABASE_URL` | ✅ | `postgres://shoplite:shoplite_password@db:5432/shoplite` |
| `LOG_LEVEL` | ✅ | `info` |

## Vérification des secrets

- `.env`, `.env.*` sont dans `.gitignore` — les fichiers d'environnement ne sont pas commités
- `.env.staging` et `.env.prod` sont générés à la volée en CI depuis les GitHub Secrets (`STAGING_DB_PASSWORD`, `PROD_DB_PASSWORD`)
- Aucun vrai mot de passe n'est présent dans le code source ou l'historique git
- Les valeurs dans `.env.example` sont des placeholders pédagogiques, pas des credentials réels

Vérification manuelle :
```bash
git log --all --full-history -- .env
git grep -i "password" -- "*.js"
```

## Audit des dépendances npm

Résultat de `npm audit` (2026-06-15) :

| Sévérité | Nombre | Paquet concerné |
|---|---|---|
| High | 1 | `uuid` via `jest-junit` |
| Moderate | 20 | `uuid` via `jest-junit` |

> `jest-junit` est une dépendance de développement uniquement (non embarquée en production). Le risque réel est faible.

Correction disponible : `npm audit fix --force` (breaking change — met à jour `jest-junit` vers v17).

## Vérification manuelle des dépendances (`npm outdated`)

| Paquet | Version actuelle | Version souhaitée | Dernière version |
|---|---|---|---|
| `cors` | 2.8.5 | 2.8.6 | 2.8.6 |
| `dotenv` | 16.4.7 | 16.6.1 | 17.4.2 |
| `express` | 4.21.2 | 4.22.2 | 5.2.1 |
| `pg` | 8.13.1 | 8.21.0 | 8.21.0 |

> Risque d'une mise à jour non testée : Express 5 est une version majeure avec des changements breaking (gestion des erreurs async, routing). Une mise à jour sans tests complets peut introduire des régressions en production.

## Classement des risques

| Risque | Niveau | Justification |
|---|---|---|
| `uuid` vulnérable dans `jest-junit` | Faible | Dev uniquement, non exposé en production |
| `express` non mis à jour (v4 → v5) | Moyen | Breaking changes potentiels sans tests |
| `dotenv` obsolète | Faible | Mise à jour mineure, peu de risques |
| Port PostgreSQL non exposé en host | Faible (maîtrisé) | Bonne pratique déjà appliquée |
| Secrets générés en CI depuis GitHub Secrets | Faible (maîtrisé) | Bonne pratique déjà appliquée |

## Checklist sécurité étudiant

- [ ] Aucun secret ou mot de passe dans le code source ou l'historique git
- [ ] `.env` et `.env.*` présents dans `.gitignore`
- [ ] `.env.example` à jour avec toutes les variables nécessaires
- [ ] Ports exposés limités au strict nécessaire
- [ ] `npm audit` lancé et vulnérabilités notées
- [ ] Image Docker basée sur une image officielle et minimale (alpine)
- [ ] Conteneur API lancé en utilisateur non-root (`USER node`)
- [ ] Logs sans données sensibles (pas de passwords dans les logs)
