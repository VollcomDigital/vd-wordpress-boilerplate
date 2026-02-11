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
make up
```

Then open:

- http://localhost:8080

To stop:

```bash
make down
```

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

---

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

---

## WP-Cron (Production)

In production, you should disable the built-in pseudo-cron and run a real scheduler:

- Set `DISABLE_WP_CRON=true`
- Use a Kubernetes `CronJob` (template included) or an external scheduler to trigger cron processing

---

## License

MIT. See [LICENSE](./LICENSE).

## Security

See [SECURITY.md](./SECURITY.md).

