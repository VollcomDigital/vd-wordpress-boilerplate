# Supply Chain & Image Verification

This repository aims to be **build-once / deploy-everywhere**:

- CI builds container images and publishes to GHCR
- Deployments should pin images **by digest**
- CI **signs** published images using **Cosign (keyless, GitHub OIDC)**

See:

- `docs/supply-chain/cosign.md`

