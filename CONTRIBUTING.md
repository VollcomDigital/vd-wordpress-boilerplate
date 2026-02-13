# Contributing

Thanks for contributing!

## Guidelines

- **No secrets**: do not commit `.env`, API keys, private certs, or credentials.
- **Keep it generic**: this is a public boilerplate; avoid organization-specific references.
- **Production-minded defaults**: prefer least privilege, read-only root filesystems, and supply-chain hygiene.

## Workflow (trunk-based)

- Create a short-lived branch from `main`
- Keep changes small and focused
- Open a PR early
- Merge back to `main` frequently

The CI builds branch-scoped container images and (on `main`) produces stable images intended to be deployed by digest.

## Local Development

See the repository README for Docker Compose commands.

Before opening a PR, run:

```bash
make qa
```

