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
  --set valkey.auth.aclUsers.default.password=<password> \
  --set api.secret.jwtSecret=<32-char-secret> \
  --set api.secret.smtpUsername=<smtp-user> \
  --set api.secret.smtpPassword=<smtp-pass> \
  --set kratos.secrets.secretsDefault=<32-char-secret> \
  --set kratos.secrets.secretsCookie=<32-char-secret> \
  --set kratos.secrets.secretsCipher=<exactly-32-char-secret> \
  --set 'kratos.secrets.smtpConnectionURI=smtp://user:pass@smtp.example.com:587/' \
  --set api.image.tag=<api-tag> \
  --set api.migration.image.tag=<api-tag> \
  --set ui.image.tag=<ui-tag>
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
  --set valkey.auth.aclUsers.default.password=<password> \
  --set api.secret.jwtSecret=<32-char-jwt-secret> \
  --set api.secret.smtpUsername=<smtp-username> \
  --set api.secret.smtpPassword=<smtp-password> \
  --set kratos.secrets.secretsDefault=<32-char-secret> \
  --set kratos.secrets.secretsCookie=<32-char-secret> \
  --set kratos.secrets.secretsCipher=<exactly-32-char-secret> \
  --set 'kratos.secrets.smtpConnectionURI=smtp://user:pass@smtp.example.com:587/' \
  --set api.image.tag=<api-tag> \
  --set api.migration.image.tag=<api-tag> \
  --set ui.image.tag=<ui-tag>
```

All secrets and image tags are required and must be provided via `--set`. The chart fails immediately with the exact `--set` flag if any are missing.

## Required Secrets

| Secret | Description |
|--------|-------------|
| `postgres.secret.password` | Internal PostgreSQL password |
| `valkey.auth.aclUsers.default.password` | Internal Valkey password |
| `api.secret.jwtSecret` | JWT signing secret (>= 32 characters) |
| `api.secret.smtpUsername` | SMTP username |
| `api.secret.smtpPassword` | SMTP password |
| `kratos.secrets.secretsDefault` | Kratos default secret (>= 32 characters) |
| `kratos.secrets.secretsCookie` | Kratos cookie secret (>= 32 characters) |
| `kratos.secrets.secretsCipher` | Kratos cipher secret (exactly 32 characters) |
| `kratos.secrets.smtpConnectionURI` | SMTP connection URI for the Kratos courier |

## Using existing Secrets

To keep secrets out of Helm values, create the Secrets yourself and point the chart at them:

| Component | Setting | Keys the Secret must hold |
|-----------|---------|---------------------------|
| PostgreSQL | `postgres.secret.existingSecret=<name>` | `password` |
| Valkey | `valkey.auth.usersExistingSecret=<name>` | `default` |
| Kratos | `kratos.secrets.enabled=false`, `kratos.secret.nameOverride=<name>` | `dsn`, `secretsDefault`, `secretsCookie`, `secretsCipher`, `smtpConnectionURI` |
| API | `api.secret.existingSecret=<name>` | `DB_PASSWORD`, `JWT_SECRET`, `REDIS_PASSWORD`, `SMTP_USERNAME`, `SMTP_PASSWORD` |

Use all four together: the chart-generated API and Kratos Secrets need the plaintext database and Valkey passwords.

## Security

Only the Kratos public API (`/self-service`, `/sessions`) is routed. The Kratos admin API has no authentication, so it stays cluster-internal; the Jovvix API reaches it through `SERVE_ADMIN_BASE_URL`.

## Required Images

| Image | Description |
|-------|-------------|
| `api.image.tag` | Jovvix API image tag (see [Docker Hub](https://hub.docker.com/r/improwised/jovvix-api/tags)) |
| `api.migration.image.tag` | Jovvix API image tag for migration (same as `api.image.tag`) |
| `ui.image.tag` | Jovvix UI image tag (see [Docker Hub](https://hub.docker.com/r/improwised/jovvix-ui/tags)) |

## Configuration

All configuration parameters are documented as comments in [values.yaml](values.yaml).
