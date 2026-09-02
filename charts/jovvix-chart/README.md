# jovvix

A Helm chart for deploying [Jovvix](https://jovvix.com) — the real-time, open-source quiz platform built for live engagement, instant feedback, and dynamic leaderboards.

## TL;DR

```bash
helm dependency build
helm install jovvix . \
  --namespace jovvix --create-namespace \
  --set global.domain=quiz.example.com \
  --set global.scheme=https \
  --set postgres.secret.password=<password> \
  --set valkey.secret.password=<password> \
  --set api.secret.jwtSecret=<32-char-secret> \
  --set api.secret.smtpUsername=<smtp-user> \
  --set api.secret.smtpPassword=<smtp-pass> \
  --set kratos.secrets.secretsDefault=<32-char-secret> \
  --set kratos.secrets.secretsCookie=<32-char-secret> \
  --set kratos.secrets.secretsCipher=<exactly-32-char-secret> \
  --set 'kratos.secrets.smtpConnectionURI=smtp://user:pass@smtp.example.com:587/'
```

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- Gateway API controller installed (default configured for [Envoy Gateway](https://gateway.envoyproxy.io); override with `--set` on `api.httpRoute.parentRefs`, `ui.httpRoute.parentRefs`, or `kratos.httpRoute.parentRefs`)

## Installing

```bash
helm dependency build
helm install jovvix . \
  --namespace jovvix --create-namespace \
  --set global.domain=quiz.example.com \
  --set global.scheme=https \
  --set postgres.secret.password=<password> \
  --set valkey.secret.password=<password> \
  --set api.secret.jwtSecret=<32-char-jwt-secret> \
  --set api.secret.smtpUsername=<smtp-username> \
  --set api.secret.smtpPassword=<smtp-password> \
  --set kratos.secrets.secretsDefault=<32-char-secret> \
  --set kratos.secrets.secretsCookie=<32-char-secret> \
  --set kratos.secrets.secretsCipher=<exactly-32-char-secret> \
  --set 'kratos.secrets.smtpConnectionURI=smtp://user:pass@smtp.example.com:587/'
```

All secrets are required and must be provided via `--set`. The chart fails immediately with the exact `--set` flag if any are missing.

## Required Secrets

| Secret | Description |
|--------|-------------|
| `postgres.secret.password` | Internal PostgreSQL password |
| `valkey.secret.password` | Internal Valkey password |
| `api.secret.jwtSecret` | JWT signing secret (>= 32 characters) |
| `api.secret.smtpUsername` | SMTP username |
| `api.secret.smtpPassword` | SMTP password |
| `kratos.secrets.secretsDefault` | Kratos default secret (>= 32 characters) |
| `kratos.secrets.secretsCookie` | Kratos cookie secret (>= 32 characters) |
| `kratos.secrets.secretsCipher` | Kratos cipher secret (exactly 32 characters) |
| `kratos.secrets.smtpConnectionURI` | SMTP connection URI for the Kratos courier |

## Configuration

All configuration parameters are documented as comments in [values.yaml](values.yaml).
