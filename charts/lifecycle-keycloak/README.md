# lifecycle-keycloak

![Version: 0.4.0](https://img.shields.io/badge/Version-0.4.0-informational?style=flat-square)  ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)  ![AppVersion: 0.0.0](https://img.shields.io/badge/AppVersion-0.0.0-informational?style=flat-square)

Keycloak instance for Lifecycle stack with automated Operator-driven setup and imports

---

## ⚠️ Important: Requirements & Dependencies

This chart does **not** install the Keycloak Operator itself. It manages the configuration (Custom Resources) that the operator processes to install Keycloak instance configured for Lifecycle Core and Lifecycle UI.

* **Required Operator:** `keycloak-operator`
* **Required CRD Version:** `keycloaks.k8s.keycloak.org/v2alpha1`
* **Installation Link:** [Keycloak Operator Helm Chart](https://goodrxoss.github.io/helm-charts/charts/keycloak-operator/)

> **Validation:** This chart includes a pre-install validation hook. If the required CRDs are not detected in your cluster, the installation will fail with a descriptive error message.

| Repository | Name | Version |
|------------|------|---------|
| https://charts.bitnami.com/bitnami | postgres(postgresql) | 15.5.19 |

---

## Installation

### Prerequisites

Before installing, ensure the operator is running and watching the target namespace. Create a `values.yaml` file to configure your instance.

```yaml
# Example minimal values.yaml
hostname: "https://keycloak.example.com"

clients:
  lifecycleUi:
    url: "https://ui.example.com"

secrets:
  githubIdp:
    enabled: true
    clientId: "your-github-id"
    clientSecret: "your-github-secret"
```

---

## Configuration Details

### 1. Identity Providers (GitHub IdP)

You can configure GitHub authentication in two ways.

> **Note:** Using `secretKeyRef` is the recommended production approach to avoid exposing credentials in Helm manifests.

#### Option A: External Secret (Recommended)

Reference an existing Kubernetes Secret. The `name` field supports Helm templates.

```yaml
secrets:
  githubIdp:
    enabled: false # We don't need the chart to create a secret

githubIdp:
  clientId:
    secretKeyRef:
      name: '{{ .Release.Name }}-custom-secret'
      key: "github-client-id"
  clientSecret:
    secretKeyRef:
      name: "my-existing-secret"
      key: "github-client-secret"

```

#### Option B: Inline Credentials (Universal but less secure)

The chart will automatically create a Secret for you.

```yaml
secrets:
  githubIdp:
    enabled: true
    clientId: "your-github-id"
    clientSecret: "your-github-secret"

```

### 2. Hostname and Client URLs

You **must** provide the actual domains during installation. These are used for redirect URIs and token issuance.

* `hostname`: The main entry point for Keycloak (e.g., `https://keycloak.example.com`).
* `clients.lifecycleUi.url`: The frontend application URL (e.g., `https://ui.example.com`).

### 3. Client Secrets (Bootstrap Only)

You can define initial secrets for your clients:

```yaml
clients:
  lifecycleCore:
    clientSecret: "lifecycle-core-secret"
  lifecycleUi:
    clientSecret: "lifecycle-ui-secret"
  lifecycleUiBackend:
    clientSecret: "lifecycle-ui-backend-secret"

```

> **Important:** These values act as **bootstrap** values. After the initial creation, if you change them in the Keycloak Admin UI, the values in Helm will no longer stay in sync.

---

## Life-cycle Management & Realm Import

This chart uses the `KeycloakRealmImport` resource for the initial setup.

* **Immutable Configuration:** Some settings (like certain realm links or fundamental structures) are hard to modify via the Operator after the initial import.
* **Re-initialization:** If you need to significantly change the realm structure that isn't being picked up by the Operator, you may need to **delete the Helm release and reinstall it**.
* **Caution:** Deleting the release might trigger the deletion of the Keycloak instance and its data (PostgreSQL), depending on your `persistence` and `reclaimPolicy` settings.

---

### Install the Chart

```shell
helm upgrade -i lifecycle-keycloak \
  oci://ghcr.io/goodrxoss/helm-charts/lifecycle-keycloak \
  --version 0.4.0 \
  -f values.yaml \
  -n lifecycle-keycloak \
  --create-namespace
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| annotations | object | `{}` |  |
| clients.lifecycleCore.clientId | string | `"lifecycle-core"` |  |
| clients.lifecycleCore.enabled | bool | `true` |  |
| clients.lifecycleUi.clientId | string | `"lifecycle-ui"` |  |
| clients.lifecycleUi.clientSecret | string | `"lifecycle-ui-secret"` |  |
| clients.lifecycleUi.enabled | bool | `true` |  |
| clients.lifecycleUi.url | string | `"http://localhost:3000"` |  |
| companyIdp.authorizationUrl | string | `nil` |  |
| companyIdp.clientId | string | `nil` |  |
| companyIdp.clientSecret | string | `nil` |  |
| companyIdp.enabled | bool | `true` |  |
| companyIdp.jwksUrl | string | `nil` |  |
| companyIdp.tokenUrl | string | `nil` |  |
| extraLabels | object | `{}` |  |
| fullnameOverride | string | `""` |  |
| githubIdp.clientId.secretKeyRef.key | string | `nil` |  |
| githubIdp.clientId.secretKeyRef.name | string | `nil` |  |
| githubIdp.clientSecret.secretKeyRef.key | string | `nil` |  |
| githubIdp.clientSecret.secretKeyRef.name | string | `nil` |  |
| githubIdp.enabled | bool | `true` |  |
| hostname | string | `"http://localhost:8080"` |  |
| hostnameStrict | bool | `true` |  |
| ingress.annotations."cert-manager.io/cluster-issuer" | string | `"letsencrypt-dns"` |  |
| ingress.annotations."nginx.ingress.kubernetes.io/proxy-buffer-size" | string | `"128k"` |  |
| ingress.annotations."nginx.ingress.kubernetes.io/proxy-buffers-number" | string | `"4"` |  |
| ingress.annotations."nginx.ingress.kubernetes.io/ssl-redirect" | string | `"true"` |  |
| ingress.className | string | `"nginx"` |  |
| ingress.enabled | bool | `true` |  |
| ingress.tls | bool | `false` |  |
| instances | int | `1` |  |
| internalIdp.clientId | string | `"internal-sso-client"` |  |
| internalIdp.displayName | string | `"Internal SSO"` |  |
| internalIdp.realm | string | `"internal"` |  |
| internalIdp.users.bootstrapUser.credsTemp | bool | `true` |  |
| internalIdp.users.bootstrapUser.email | string | `"lifecycle@example.com"` |  |
| internalIdp.users.bootstrapUser.firstName | string | `"Lifecycle"` |  |
| internalIdp.users.bootstrapUser.lastName | string | `"Bootstrap"` |  |
| internalIdp.users.bootstrapUser.password | string | `"lifecycle"` |  |
| internalIdp.users.bootstrapUser.username | string | `"lifecycle"` |  |
| nameOverride | string | `""` |  |
| postgres.auth.database | string | `"keycloak"` |  |
| postgres.auth.existingSecret | string | `"{{ include \"lifecycle-keycloak.postgresSecretName\" . }}"` |  |
| postgres.auth.secretKeys.adminPasswordKey | string | `"POSTGRES_ADMIN_PASSWORD"` |  |
| postgres.auth.secretKeys.userPasswordKey | string | `"POSTGRES_USER_PASSWORD"` |  |
| postgres.auth.username | string | `"keycloak"` |  |
| postgres.enabled | bool | `true` |  |
| postgres.fullnameOverride | string | `""` |  |
| postgres.image.repository | string | `"bitnamilegacy/postgresql"` |  |
| postgres.primary.persistence.enabled | bool | `true` |  |
| postgres.primary.persistence.size | string | `"1Gi"` |  |
| postgres.primary.resources.limits.cpu | string | `"200m"` |  |
| postgres.primary.resources.limits.memory | string | `"256Mi"` |  |
| postgres.primary.resources.requests.cpu | string | `"100m"` |  |
| postgres.primary.resources.requests.memory | string | `"128Mi"` |  |
| realm | string | `"lifecycle"` |  |
| realmDisplayName | string | `"Lifecycle"` |  |
| secrets.bootstrapAdmin.annotations | list | `[]` |  |
| secrets.bootstrapAdmin.enabled | bool | `true` |  |
| secrets.bootstrapAdmin.fullnameOverride | string | `""` |  |
| secrets.bootstrapAdmin.password | string | `""` |  |
| secrets.bootstrapAdmin.username | string | `"bootstrap-admin"` |  |
| secrets.githubIdp.annotations | list | `[]` |  |
| secrets.githubIdp.clientId | string | `nil` |  |
| secrets.githubIdp.clientSecret | string | `nil` |  |
| secrets.githubIdp.enabled | bool | `false` |  |
| secrets.githubIdp.fullnameOverride | string | `""` |  |
| secrets.postgres.adminPassword | string | `""` |  |
| secrets.postgres.annotations | list | `[]` |  |
| secrets.postgres.enabled | bool | `true` |  |
| secrets.postgres.fullnameOverride | string | `""` |  |
| secrets.postgres.userPassword | string | `""` |  |
