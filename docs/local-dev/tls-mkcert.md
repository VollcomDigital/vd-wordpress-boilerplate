# Trusted Local TLS with mkcert

This repo supports trusted local HTTPS with:

- `mkcert` for certificate generation
- Caddy profile `tls-trusted` for reverse proxy

## Why

The default TLS profile uses Caddy internal certs (quick setup, browser warning).  
For day-to-day local dev (cookies, OAuth callbacks, browser APIs), trusted certs are better.

## Prerequisites

- `mkcert` installed
  - macOS (Homebrew): `brew install mkcert nss`
  - Linux: see https://github.com/FiloSottile/mkcert#linux
  - Windows (Chocolatey): `choco install mkcert`

## Steps

1. Configure `.env`:

```dotenv
WP_HOME=https://wp.localhost:8443
WP_SITEURL=https://wp.localhost:8443/wp
```

2. Generate trusted certs:

```bash
make certs-mkcert
```

This creates (gitignored):

- `.certs/wp.localhost.pem`
- `.certs/wp.localhost-key.pem`

3. Start stack:

```bash
make bootstrap-tls-trusted
```

4. Open:

- https://wp.localhost:8443

## Troubleshooting

- If you still see cert warnings, re-run `mkcert -install` and restart your browser.
- Ensure your OS trust store accepted mkcert's local CA.

