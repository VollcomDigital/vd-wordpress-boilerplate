# Uploads Offload to S3-Compatible Object Storage (Recommended)

In Kubernetes, scaling WordPress beyond 1 replica usually requires avoiding a shared filesystem for uploads.

Recommended approach: **offload uploads to an S3-compatible bucket**.

## Plugin option: humanmade/s3-uploads

One popular open-source option:

- https://github.com/humanmade/S3-Uploads

Install (Bedrock / Composer):

```bash
composer require humanmade/s3-uploads
```

> The plugin reads configuration from PHP constants. This boilerplate can define
> those constants from environment variables (see `config/application.php`).

## Env vars / constants (typical)

At minimum:

- `S3_UPLOADS_BUCKET`
- `S3_UPLOADS_REGION` (AWS) or omit for some S3-compatible providers

Auth options:

- Key/secret in a Secret:
  - `S3_UPLOADS_KEY`
  - `S3_UPLOADS_SECRET`
- Or workload identity / instance profile:
  - `S3_UPLOADS_USE_INSTANCE_PROFILE=true`

S3-compatible endpoints (MinIO, Ceph, etc):

- `S3_UPLOADS_ENDPOINT=https://minio.example.com`
- `S3_UPLOADS_PATH_STYLE_ENDPOINT=true`

Public bucket URL (CDN or direct):

- `S3_UPLOADS_BUCKET_URL=https://cdn.example.com`

## Helm integration

1. Keep uploads PVC disabled:

```yaml
uploads:
  persistence:
    enabled: false
```

2. Provide env vars via a ConfigMap/Secret you manage, then reference them:

```yaml
config:
  existingConfigMap: wp-env
secret:
  existingSecret: wp-secrets
```

See also:

- `docs/kubernetes/configmap-bedrock.example.yaml`
- `docs/kubernetes/secrets-required.md`
- `docs/kubernetes/external-secrets/`
- `docs/kubernetes/sealed-secrets/`

