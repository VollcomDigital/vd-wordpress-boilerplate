# Modern Cloud-Native WordPress Boilerplate (Bedrock)

A production-minded WordPress boilerplate based on **[Roots Bedrock](https://roots.io/bedrock/)**, designed for:

- Local development with **Docker Compose** (profiles for optional services)
- Hardened, reproducible **container builds** (multi-stage)
- **Kubernetes-first** deployment via **Helm**
- Supply-chain and security gates in **GitHub Actions**

> This repo is intentionally generic and safe to publish: no internal domains, no secrets, and no private themes/plugins/submodules.

---

## Quickstart (Local Development)

### Prerequisites

- Docker + Docker Compose v2
- `make`

### Run it

```bash
cp .env.example .env
make bootstrap
```

Then open:

- http://localhost:8080

`make bootstrap` also runs a WP-CLI install if the site isn't installed yet.
Defaults (override in `.env`):

- `WP_SITE_TITLE` (default: `Boilerplate`)
- `WP_ADMIN_USER` (default: `admin`)
- `WP_ADMIN_PASSWORD` (default: `admin`)
- `WP_ADMIN_EMAIL` (default: `admin@example.com`)

You can re-run:

```bash
make wp-install
```

To stop:

```bash
make down
```

### Optional: local HTTPS (TLS)

This repo includes an optional Caddy reverse proxy for local HTTPS:

```bash
# Update .env so WP_HOME/WP_SITEURL use https://wp.localhost:8443
make bootstrap-tls
```

URL:

- https://wp.localhost:8443

Note: Caddy uses a locally-generated certificate (browser will warn). For a trusted cert, use `mkcert` and configure Caddy with your generated certs.

### Optional profiles (dev conveniences)

```bash
# Adds MailHog (SMTP capture UI at http://localhost:8025)
make up-mail

# Adds phpMyAdmin (http://localhost:8081)
make up-dbadmin

# Adds metrics exporters (Prometheus scrape targets)
make up-observability
```

---

## Production Images (Hardened)

This boilerplate provides:

- A PHP-FPM image (Bedrock + WordPress via Composer)
- A web image (Nginx, non-root)
- Secure-by-default runtime posture (drop caps, no privilege escalation, read-only root filesystem where possible)

Images are intended to be built in CI and deployed **by digest** (build once, deploy everywhere).

### Branch-based images

The included GitHub Actions workflow builds and publishes images for each branch:

- `ghcr.io/<owner>/<repo>-php:<branch>`
- `ghcr.io/<owner>/<repo>-nginx:<branch>`

For production, prefer pinning by **digest** instead of tags.

---

## Configuration (12-factor)

- Local dev uses a `.env` file (see `.env.example`).
- Production should set env vars via **Kubernetes Secrets/ConfigMaps** (do not bake secrets into images).

Common toggles:

- `DISABLE_WP_CRON=true` (production)
- `DISALLOW_FILE_MODS=true` (production hardening)
- `WP_CACHE=true` + `WP_REDIS_HOST=...` (optional Redis object cache; plugin required)

## Deploy to Kubernetes (Helm)

Helm chart: `helm/wp-boilerplate`

High-level steps:

1. Push images to a registry (GHCR workflow included).
2. Create Kubernetes Secrets for database credentials and WordPress salts/keys.
3. Install the chart and pin images by digest.

Example:

```bash
helm upgrade --install wp helm/wp-boilerplate \
  --namespace wp --create-namespace \
  --set image.php.repository=ghcr.io/OWNER/REPO-php \
  --set image.web.repository=ghcr.io/OWNER/REPO-nginx \
  --set image.php.digest=sha256:... \
  --set image.web.digest=sha256:...
```

### Uploads storage strategy

Preferred (cloud-native): use an S3-compatible uploads plugin (no shared PVC required).

Alternative (simple clusters): enable the chart's `uploads.persistence` option to mount a PVC.

Details: `docs/kubernetes/uploads-s3.md`

---

## WP-Cron (Production)

In production, you should disable the built-in pseudo-cron and run a real scheduler:

- Set `DISABLE_WP_CRON=true`
- Use a Kubernetes `CronJob` (template included) or an external scheduler to trigger cron processing

## Secrets on Kubernetes

Recommended approaches:

- External Secrets Operator (ESO)
- SealedSecrets

See `docs/kubernetes/` for templates and required keys.

## Supply chain / image verification

CI signs published images (keyless Cosign). See `docs/supply-chain/cosign.md`.

---

## License

MIT. See [LICENSE](./LICENSE).

## Security

See [SECURITY.md](./SECURITY.md).

