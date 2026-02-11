# wp-boilerplate Helm Chart

This chart deploys the boilerplate as a hardened, Kubernetes-native workload:

- **Nginx** (non-root) serving Bedrock `web/`
- **PHP-FPM** (non-root) running WordPress
- Shared **FPM socket** via `emptyDir`
- Optional **uploads PVC** (or offload uploads to object storage)
- Optional **HPA / PDB / NetworkPolicy**
- Optional **CronJob** to replace WP-Cron

## Quick install

> Recommended: deploy **by image digest** (build once, deploy everywhere).

```bash
helm upgrade --install wp ./helm/wp-boilerplate \
  --namespace wp --create-namespace \
  --set image.php.repository=ghcr.io/OWNER/REPO-php \
  --set image.web.repository=ghcr.io/OWNER/REPO-nginx \
  --set image.php.digest=sha256:... \
  --set image.web.digest=sha256:...
```

## Configuration (ConfigMap + Secret)

The app uses Bedrock-style env vars.

This chart creates a ConfigMap (`<release>-env`) unless `config.existingConfigMap` is provided.

### Secrets

For production, prefer **External Secrets** or **SealedSecrets**.

You can either:

- Provide `secret.existingSecret`, or
- Set `secret.create=true` and populate `secret.data` (not recommended)

Expected Secret keys include:

- `DB_PASSWORD`
- `AUTH_KEY`, `SECURE_AUTH_KEY`, `LOGGED_IN_KEY`, `NONCE_KEY`
- `AUTH_SALT`, `SECURE_AUTH_SALT`, `LOGGED_IN_SALT`, `NONCE_SALT`

## Uploads storage strategy

### Recommended (cloud-native): S3-compatible offload

Use a uploads offload plugin (example: `humanmade/s3-uploads`) so you can scale replicas without shared storage.

### Alternative: PVC

Set:

```yaml
uploads:
  persistence:
    enabled: true
    size: 10Gi
```

If you scale above 1 replica without a shared RWX filesystem, uploads consistency will break.

## WP-Cron

Production guidance:

- Set `DISABLE_WP_CRON=true`
- Enable the chart CronJob:

```yaml
cron:
  enabled: true
  schedule: "*/5 * * * *"
```

