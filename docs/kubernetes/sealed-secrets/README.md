# SealedSecrets Examples

These templates assume you are using Bitnami SealedSecrets:

- https://github.com/bitnami-labs/sealed-secrets

## Typical flow

1. Install the Sealed Secrets controller in your cluster
2. Create a normal Secret locally (never commit it)
3. Use `kubeseal` to encrypt it into a `SealedSecret`
4. Commit the `SealedSecret` manifest to git

This chart can then reference the created Secret via `secret.existingSecret`.

Files:

- `sealedsecret-wordpress.example.yaml` (template)

