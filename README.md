# Stalwart Helm Chart

Helm chart for deploying [Stalwart Mail Server](https://stalw.art/) on Kubernetes.

This chart currently deploys Stalwart as a clustered `StatefulSet` and expects external services for storage:

- PostgreSQL for data, directory, and full-text search
- Valkey / Redis for lookup storage
- S3-compatible object storage for blobs
- NATS for cluster coordination

## What This Chart Deploys

- `StatefulSet` for Stalwart replicas
- Headless service for stable pod identity
- Main service for external access
- ConfigMap with the generated `config.toml`
- Optional cert-manager `Issuer` and `Certificate`

## Prerequisites

You must provide these Kubernetes secrets before installing the chart:

- Admin secret: `stalwart-admin`
  - `username`
  - `password`
- PostgreSQL secret: `stalwart-db-user`
  - `username`
  - `password`
- Valkey secret: `valkey-stalwart-valkey`
  - `password`
  - Optional: `username`
- S3 secret: `stalwart-secret`
  - `bucket`
  - `endpoint`
  - `access-key`
  - `secret-key`
- Optional DKIM secret: `stalwart-dkim`
  - One or more private key files referenced by `stalwart.dkim.signatures[*].privateKeyFile`
- Optional NATS auth secret when `clustering.nats.authEnabled=true`
  - `username`
  - `password`

## Default Architecture

- Cluster mode is enabled by default.
- The chart deploys `3` Stalwart replicas.
- Pod ordinals start at `1` to match Stalwart cluster node ID expectations.
- PostgreSQL, Valkey, S3, and NATS endpoints are configured through `values.yaml`.
- Sensitive credentials are read from existing Kubernetes secrets.

## Installation

Review and adjust [`values.yaml`](./values.yaml), then install:

```bash
helm install stalwart .
```

To install into a namespace:

```bash
helm install stalwart . -n mail --create-namespace
```

## Important Values

### Core

- `image.repository`
- `image.tag`
- `stalwart.defaultHostname`
- `clustering.replicas`

### PostgreSQL

- `postgresql.host`
- `postgresql.port`
- `postgresql.database`
- `postgresql.secretName`

### Valkey

- `valkey.host`
- `valkey.port`
- `valkey.database`
- `valkey.secretName`
- `valkey.tls`

### S3

- `s3.region`
- `s3.secretName`
- `s3.bucketKey`
- `s3.endpointKey`
- `s3.accessKeyKey`
- `s3.secretKeyKey`

### Admin Secret

- `stalwart.admin.secretName`
- `stalwart.admin.usernameKey`
- `stalwart.admin.passwordKey`

### DKIM

- `stalwart.dkim.enabled`
- `stalwart.dkim.secretName`
- `stalwart.dkim.sign`
- `stalwart.dkim.signatures`

### NATS Coordination

- `clustering.nats.addresses`
- `clustering.nats.authEnabled`
- `clustering.nats.credentialsSecret`

## DKIM

When `stalwart.dkim.enabled=true`, the chart mounts the secret defined by `stalwart.dkim.secretName` at:

```text
/etc/stalwart/dkim
```

Each DKIM signature entry references a file from that secret:

```yaml
stalwart:
  dkim:
    enabled: true
    secretName: stalwart-dkim
    sign:
      - default
    signatures:
      - name: default
        domain: example.com
        selector: mail
        privateKeyFile: default.key
```

## TLS Resources

The chart includes:

- [`templates/issuer.yaml`](./templates/issuer.yaml)
- [`templates/certificate.yaml`](./templates/certificate.yaml)

These create a cert-manager `Issuer` and `Certificate` for the Stalwart TLS secret mounted into the pod.

If you terminate TLS entirely outside Stalwart, you may not need these resources. Be careful with mail protocols such as SMTPS, IMAPS, and HTTPS before removing them.

## Operations

Check pod status:

```bash
kubectl get pods -n <namespace> -l app.kubernetes.io/instance=<release>
```

Check logs:

```bash
kubectl logs -n <namespace> -l app.kubernetes.io/name=stalwart -f
```

Check service:

```bash
kubectl get svc -n <namespace> <release>-stalwart
```

Check generated configuration:

```bash
kubectl get configmap -n <namespace> <release>-stalwart -o yaml
```

Check certificate:

```bash
kubectl get certificate -n <namespace> <release>-stalwart-tls
```

Check required secrets:

```bash
kubectl get secret -n <namespace> stalwart-admin
kubectl get secret -n <namespace> stalwart-db-user
kubectl get secret -n <namespace> valkey-stalwart-valkey
kubectl get secret -n <namespace> stalwart-secret
```

If DKIM is enabled:

```bash
kubectl get secret -n <namespace> stalwart-dkim
```

## Post-Install Checklist

1. Verify all pods are `Running` and `Ready`.
2. Confirm PostgreSQL, Valkey, S3, and NATS endpoints are reachable from the cluster.
3. Configure DNS records for your mail hostname.
4. Configure MX, SPF, DKIM, and DMARC records.
5. Sign in to the Stalwart admin UI and complete domain and account setup.
6. Test SMTP, IMAP, and webmail connectivity.

## References

- Stalwart documentation: https://stalw.art/docs/
- Chart values: [`values.yaml`](./values.yaml)
