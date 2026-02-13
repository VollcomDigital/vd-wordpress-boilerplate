# Cosign (Keyless) Verification

The container build workflow signs published images using **Cosign** with **GitHub OIDC** (no long-lived signing keys in the repo).

Workflow:

- `.github/workflows/container-build.yml`

## Verify a published image

Install cosign:

- https://docs.sigstore.dev/cosign/system_config/installation/

Then verify an image digest:

```bash
cosign verify \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity "https://github.com/<owner>/<repo>/.github/workflows/container-build.yml@refs/heads/<branch>" \
  ghcr.io/<owner>/<repo>-php@sha256:<digest>
```

Repeat for the nginx image:

```bash
cosign verify \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity "https://github.com/<owner>/<repo>/.github/workflows/container-build.yml@refs/heads/<branch>" \
  ghcr.io/<owner>/<repo>-nginx@sha256:<digest>
```

Notes:

- Images are only published/signed on non-PR events in the workflow (PRs build but do not push).
- Prefer verifying **by digest**, not by tag.

## SBOM / provenance (optional)

The workflow also publishes SBOM/provenance attestations via BuildKit.

Depending on your cosign version and registry support, you can fetch them:

```bash
cosign download sbom ghcr.io/<owner>/<repo>-php@sha256:<digest>
```

```bash
cosign download attestation ghcr.io/<owner>/<repo>-php@sha256:<digest>
```

