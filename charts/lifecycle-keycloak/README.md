# lifecycle-keycloak

![Version: 0.7.4](https://img.shields.io/badge/Version-0.7.4-informational?style=flat-square)  ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)  ![AppVersion: 0.0.0](https://img.shields.io/badge/AppVersion-0.0.0-informational?style=flat-square)

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
| https://charts.bitnami.com/bitnami | keycloakPostgres(postgresql) | 15.5.19 |

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

### 4. Lifecycle MCP OAuth Client

The chart can configure a public PKCE client and anonymous Dynamic Client Registration policies for the Lifecycle MCP endpoint. These values are disabled by default and can be enabled when the Lifecycle app exposes `/mcp`.

```yaml
clients:
  lifecycleMcp:
    enabled: true
    resourceUrl: "https://app.example.com/mcp"

clientRegistrationPolicies:
  anonymous:
    enabled: true
    trustedHosts:
      hosts:
        - 127.0.0.1
        - localhost
    allowedRegistrationWebOrigins:
      origins:
        - "http://localhost:6274"
        - "http://127.0.0.1:6274"
```

The MCP client scope emits the configured resource URL as the access-token audience and maps the `githubUsername` user attribute into the `github_username` claim.

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
  --version 0.7.4 \
  -f values.yaml \
  -n lifecycle-keycloak \
  --create-namespace
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| annotations | object | `{}` |  |
| clientRegistrationPolicies.anonymous.allowedClientScopes.enabled | bool | `true` |  |
| clientRegistrationPolicies.anonymous.allowedClientScopes.name | string | `"Allowed Client Scopes"` |  |
| clientRegistrationPolicies.anonymous.allowedClientScopes.scopes[0] | string | `"roles"` |  |
| clientRegistrationPolicies.anonymous.allowedClientScopes.scopes[1] | string | `"profile"` |  |
| clientRegistrationPolicies.anonymous.allowedClientScopes.scopes[2] | string | `"basic"` |  |
| clientRegistrationPolicies.anonymous.allowedClientScopes.scopes[3] | string | `"email"` |  |
| clientRegistrationPolicies.anonymous.allowedClientScopes.scopes[4] | string | `"offline_access"` |  |
| clientRegistrationPolicies.anonymous.allowedClientScopes.scopes[5] | string | `"lifecycle-mcp"` |  |
| clientRegistrationPolicies.anonymous.allowedRegistrationWebOrigins.enabled | bool | `true` |  |
| clientRegistrationPolicies.anonymous.allowedRegistrationWebOrigins.name | string | `"Allowed Registration Web Origins"` |  |
| clientRegistrationPolicies.anonymous.allowedRegistrationWebOrigins.origins[0] | string | `"http://localhost:6274"` |  |
| clientRegistrationPolicies.anonymous.allowedRegistrationWebOrigins.origins[1] | string | `"http://127.0.0.1:6274"` |  |
| clientRegistrationPolicies.anonymous.enabled | bool | `false` |  |
| clientRegistrationPolicies.anonymous.extraPolicies | list | `[]` |  |
| clientRegistrationPolicies.anonymous.maxClients.count | int | `200` |  |
| clientRegistrationPolicies.anonymous.maxClients.enabled | bool | `true` |  |
| clientRegistrationPolicies.anonymous.maxClients.name | string | `"Max Clients Limit"` |  |
| clientRegistrationPolicies.anonymous.trustedHosts.clientUrisMustMatch | bool | `true` |  |
| clientRegistrationPolicies.anonymous.trustedHosts.enabled | bool | `true` |  |
| clientRegistrationPolicies.anonymous.trustedHosts.hostSendingRegistrationRequestMustMatch | bool | `true` |  |
| clientRegistrationPolicies.anonymous.trustedHosts.hosts[0] | string | `"127.0.0.1"` |  |
| clientRegistrationPolicies.anonymous.trustedHosts.hosts[1] | string | `"localhost"` |  |
| clientRegistrationPolicies.anonymous.trustedHosts.name | string | `"Trusted Hosts"` |  |
| clientScopes.lifecycleMcp.audienceMapper.audience | string | `nil` |  |
| clientScopes.lifecycleMcp.audienceMapper.enabled | bool | `true` |  |
| clientScopes.lifecycleMcp.audienceMapper.name | string | `"Lifecycle MCP resource audience"` |  |
| clientScopes.lifecycleMcp.description | string | `"Claims required by Lifecycle MCP clients."` |  |
| clientScopes.lifecycleMcp.enabled | bool | `false` |  |
| clientScopes.lifecycleMcp.githubUsernameMapper.claimName | string | `"github_username"` |  |
| clientScopes.lifecycleMcp.githubUsernameMapper.enabled | bool | `true` |  |
| clientScopes.lifecycleMcp.githubUsernameMapper.name | string | `"Github username"` |  |
| clientScopes.lifecycleMcp.githubUsernameMapper.userAttribute | string | `"githubUsername"` |  |
| clientScopes.lifecycleMcp.name | string | `"lifecycle-mcp"` |  |
| clientScopes.lifecycleMcp.protocolMappers | list | `[]` |  |
| clients.lifecycleCore.clientId | string | `"lifecycle-core"` |  |
| clients.lifecycleCore.enabled | bool | `true` |  |
| clients.lifecycleMcp.attributes | object | `{}` |  |
| clients.lifecycleMcp.clientId | string | `"lifecycle-mcp"` |  |
| clients.lifecycleMcp.defaultClientScopes[0] | string | `"roles"` |  |
| clients.lifecycleMcp.defaultClientScopes[1] | string | `"profile"` |  |
| clients.lifecycleMcp.defaultClientScopes[2] | string | `"basic"` |  |
| clients.lifecycleMcp.defaultClientScopes[3] | string | `"email"` |  |
| clients.lifecycleMcp.defaultClientScopes[4] | string | `"lifecycle-mcp"` |  |
| clients.lifecycleMcp.directAccessGrantsEnabled | bool | `false` |  |
| clients.lifecycleMcp.enabled | bool | `false` |  |
| clients.lifecycleMcp.fullScopeAllowed | bool | `true` |  |
| clients.lifecycleMcp.name | string | `"Lifecycle MCP"` |  |
| clients.lifecycleMcp.optionalClientScopes[0] | string | `"offline_access"` |  |
| clients.lifecycleMcp.pkceCodeChallengeMethod | string | `"S256"` |  |
| clients.lifecycleMcp.protocolMappers | list | `[]` |  |
| clients.lifecycleMcp.publicClient | bool | `true` |  |
| clients.lifecycleMcp.redirectUris[0] | string | `"http://127.0.0.1"` |  |
| clients.lifecycleMcp.redirectUris[1] | string | `"http://localhost:3000/callback"` |  |
| clients.lifecycleMcp.redirectUris[2] | string | `"http://localhost:8080/callback"` |  |
| clients.lifecycleMcp.resourceUrl | string | `"http://localhost:3000/mcp"` |  |
| clients.lifecycleMcp.serviceAccountsEnabled | bool | `false` |  |
| clients.lifecycleMcp.standardFlowEnabled | bool | `true` |  |
| clients.lifecycleMcp.webOrigins[0] | string | `"+"` |  |
| clients.lifecycleUi.clientId | string | `"lifecycle-ui"` |  |
| clients.lifecycleUi.clientSecret.secretKeyRef.key | string | `nil` |  |
| clients.lifecycleUi.clientSecret.secretKeyRef.name | string | `nil` |  |
| clients.lifecycleUi.enabled | bool | `true` |  |
| clients.lifecycleUi.url | string | `"http://localhost:3000"` |  |
| companyIdp.authorizationUrl | string | `nil` |  |
| companyIdp.clientId | string | `nil` |  |
| companyIdp.clientSecret | string | `nil` |  |
| companyIdp.enabled | bool | `true` |  |
| companyIdp.jwksUrl | string | `nil` |  |
| companyIdp.tokenUrl | string | `nil` |  |
| externalDatabase.database | string | `"keycloak"` |  |
| externalDatabase.enabled | bool | `false` |  |
| externalDatabase.host | string | `nil` |  |
| externalDatabase.password.secretKeyRef.key | string | `nil` |  |
| externalDatabase.password.secretKeyRef.name | string | `nil` |  |
| externalDatabase.port | int | `5432` |  |
| externalDatabase.username | string | `"keycloak"` |  |
| externalDatabase.vendor | string | `"postgres"` |  |
| extraLabels | object | `{}` |  |
| fullnameOverride | string | `""` |  |
| githubIdp.clientId.secretKeyRef.key | string | `nil` |  |
| githubIdp.clientId.secretKeyRef.name | string | `nil` |  |
| githubIdp.clientSecret.secretKeyRef.key | string | `nil` |  |
| githubIdp.clientSecret.secretKeyRef.name | string | `nil` |  |
| githubIdp.enabled | bool | `true` |  |
| githubIdp.githubJsonFormat | bool | `true` |  |
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
| keycloakPostgres.auth.database | string | `"keycloak"` |  |
| keycloakPostgres.auth.existingSecret | string | `"{{ include \"lifecycle-keycloak.postgresSecretName\" . }}"` |  |
| keycloakPostgres.auth.secretKeys.adminPasswordKey | string | `"POSTGRES_ADMIN_PASSWORD"` |  |
| keycloakPostgres.auth.secretKeys.userPasswordKey | string | `"POSTGRES_USER_PASSWORD"` |  |
| keycloakPostgres.auth.username | string | `"keycloak"` |  |
| keycloakPostgres.enabled | bool | `true` |  |
| keycloakPostgres.fullnameOverride | string | `""` |  |
| keycloakPostgres.image.repository | string | `"bitnamilegacy/postgresql"` |  |
| keycloakPostgres.nameOverride | string | `"postgres"` |  |
| keycloakPostgres.primary.persistence.enabled | bool | `true` |  |
| keycloakPostgres.primary.persistence.size | string | `"1Gi"` |  |
| keycloakPostgres.primary.resources.limits.cpu | string | `"200m"` |  |
| keycloakPostgres.primary.resources.limits.memory | string | `"256Mi"` |  |
| keycloakPostgres.primary.resources.requests.cpu | string | `"100m"` |  |
| keycloakPostgres.primary.resources.requests.memory | string | `"128Mi"` |  |
| nameOverride | string | `""` |  |
| parentChartName | string | `"lifecycle"` |  |
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
| secrets.lifecycleUi.annotations | list | `[]` |  |
| secrets.lifecycleUi.clientSecret | string | `nil` |  |
| secrets.lifecycleUi.enabled | bool | `true` |  |
| secrets.lifecycleUi.fullnameOverride | string | `""` |  |
| secrets.postgres.adminPassword | string | `""` |  |
| secrets.postgres.annotations | list | `[]` |  |
| secrets.postgres.enabled | bool | `true` |  |
| secrets.postgres.fullnameOverride | string | `""` |  |
| secrets.postgres.userPassword | string | `""` |  |
