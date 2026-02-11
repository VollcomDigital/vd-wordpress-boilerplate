# Required Secrets / Env Vars (Bedrock)

This boilerplate follows Bedrock's environment-variable configuration model.

## Required env vars (ConfigMap)

Typically stored in a ConfigMap (non-secret):

- `WP_ENV`
- `WP_HOME`
- `WP_SITEURL`
- `DB_HOST`
- `DB_NAME`
- `DB_USER`
- `DB_PREFIX` (optional)

## Required secret keys (Secret)

Store these in a Kubernetes Secret (or via External Secrets / SealedSecrets):

### Database

- `DB_PASSWORD`

### WordPress salts/keys

- `AUTH_KEY`
- `SECURE_AUTH_KEY`
- `LOGGED_IN_KEY`
- `NONCE_KEY`
- `AUTH_SALT`
- `SECURE_AUTH_SALT`
- `LOGGED_IN_SALT`
- `NONCE_SALT`

Generate secure salts:

- https://roots.io/salts.html

## Optional secret keys

- `WP_REDIS_PASSWORD` (if your Redis requires auth)

## Helm chart integration

The Helm chart supports:

- `secret.existingSecret`: reference a Secret created elsewhere (recommended)
- `secret.create=true` + `secret.data`: creates a Secret from Helm values (not recommended for real environments)

