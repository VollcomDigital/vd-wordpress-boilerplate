# Kubernetes Deployment Notes

This boilerplate is designed to be deployed to Kubernetes via Helm:

- Chart: `helm/wp-boilerplate`
- Prefer **build once, deploy everywhere** by pinning images **by digest**
- Prefer **object storage** for uploads (S3-compatible) to avoid shared PVCs

## Secrets management (recommended)

Do not commit secrets to git.

Recommended approaches:

1. **External Secrets Operator (ESO)** (pull from a secret manager at runtime)
2. **SealedSecrets** (encrypt Secret manifests for safe storage in git)

See:

- `docs/kubernetes/secrets-required.md`
- `docs/kubernetes/external-secrets/`
- `docs/kubernetes/sealed-secrets/`

