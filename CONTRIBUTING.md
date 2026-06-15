# Contribution

## Branches

| Branche     | Usage                                                    |
|-------------|----------------------------------------------------------|
| `main`      | Production - protégée, livraison via release tag         |
| `develop`   | Intégration - branche de base pour les fonctionnalités   |
| `feature/*` | Développement d'une fonctionnalité                       |
| `hotfix/*`  | Correction urgente depuis `main`                         |

### Règles
- `main` est protégée : pas de push direct, uniquement des PR mergées
- `feature/*` se merge dans `develop`
- `hotfix/*` se merge dans `main` puis backport dans `develop`

## Commits

Structure conventionnelle :

```
type(scope): description courte

- Détail optionnel
- Breaking change si nécessaire
```

Types : `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `ci`, `security`

Exemples :
- `feat(api): ajoute route /products avec pagination`
- `fix(ci): correction du healthcheck PostgreSQL`
- `docs(readme): ajoute section rollback`

## Pull Requests

1. Ouvrir la PR vers `develop` (ou `main` pour hotfix)
2. Titre explicite reprenant le type et le scope
3. Description incluant :
   - Objectif de la PR
   - Modifications apportées
   - Tests effectués
4. Assigner un reviewer

## Code Review

- Vérifier la cohérence avec l'architecture existante
- S'assurer que les tests passent (CI verte)
- Vérifier l'absence de secrets dans le code
- Valider la couverture de code (≥ 80% lignes)
- Approuver ou demander des modifications

## PR Template

Le template est défini dans `.github/pull_request_template.md` :

```
## Objectif

## Vérifications
- [ ] Tests lancés
- [ ] Docker build OK
- [ ] Smoke test OK

## Risques et rollback
```
