# External Secrets Operator (ESO) Examples

These examples assume you are using:

- https://external-secrets.io/

They are intentionally templates with placeholders.

Typical flow:

1. Install ESO in your cluster
2. Configure a `SecretStore` / `ClusterSecretStore` for your provider
3. Create an `ExternalSecret` that materializes a Kubernetes Secret containing:
   - `DB_PASSWORD`
   - WordPress salts/keys
4. Point Helm to that Secret using `secret.existingSecret`

Files:

- `clustersecretstore-aws-secretsmanager.example.yaml` (template)
- `externalsecret-wordpress.example.yaml` (template)

