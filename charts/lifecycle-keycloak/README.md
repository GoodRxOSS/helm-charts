# lifecycle-keycloak

![Version: 0.7.6](https://img.shields.io/badge/Version-0.7.6-informational?style=flat-square)  ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)  ![AppVersion: 0.0.0](https://img.shields.io/badge/AppVersion-0.0.0-informational?style=flat-square)

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

### 3. Lifecycle API Credentials

This chart bootstraps two fixed, confidential service-account clients:

* `lifecycle-api-keycloak-management` is directly assigned only
  `manage-clients` and `manage-realm` for the Lifecycle web process. Keycloak
  expands the built-in `manage-realm` composites in its token.
* `lifecycle-api-principal-sync` is directly assigned only `view-users` and
  `query-users` for the Lifecycle worker. On Keycloak 26.4.7, `query-users`
  also adds its built-in `query-groups` composite to the token.

Their Kubernetes Secrets are lookup-stable and remain in place during rollback.
`KeycloakRealmImport` creates the clients during the initial realm import. The
Lifecycle API, not this chart, configures MCP scopes, audiences, and dynamic
client registration when an administrator enables MCP.

Use existing Secrets when another secret manager owns the values:

```yaml
clients:
  lifecycleApiKeycloakManagement:
    clientSecret:
      secretKeyRef:
        name: lifecycle-api-keycloak-management
        key: clientSecret
  lifecycleApiPrincipalSync:
    clientSecret:
      secretKeyRef:
        name: lifecycle-api-principal-sync
        key: clientSecret

secrets:
  apiKeycloakManagement:
    enabled: false
  apiPrincipalSync:
    enabled: false

```

`KeycloakRealmImport` is one-shot: upgrading an installation whose Lifecycle
realm already exists will not add either client. Create the missing clients
externally before enabling MCP (`lifecycle-api-keycloak-management`) or relying
on the API-key owner sweep (`lifecycle-api-principal-sync`). Each is an enabled
confidential OpenID Connect service-account client with interactive and
direct-access flows disabled, `fullScopeAllowed: false`, and scope mappings for
exactly its `realm-management` roles: `manage-clients` + `manage-realm` for the
management client, `view-users` + `query-users` for principal sync. Each client
secret must match the Kubernetes Secret selected by the corresponding
`clients.*.clientSecret.secretKeyRef`.

#### Existing-realm MCP policy migration and recovery

This chart bootstraps credentials and fresh-realm clients only. The Lifecycle
web/API process performs MCP Keycloak reconciliation when an administrator
enables MCP; a Helm install or upgrade does not reconcile or repair dynamic
client-registration policies.

On enable, Lifecycle reconciles and verifies its MCP scopes, mappers, profiles,
policies, and anonymous registration components. It may remove the anonymous
`Trusted Hosts` component only when exactly one exists and it matches the stock
Keycloak posture: both `host-sending-registration-request-must-match` and
`client-uris-must-match` are `true`. Lifecycle never overwrites, removes, or
replaces a customized, duplicated, or otherwise drifted `Trusted Hosts` policy.
Such a conflict fails enablement safely and requires a Keycloak operator to
restore an unambiguous compatible posture before the administrator retries.

Disabling Lifecycle MCP closes Lifecycle MCP access only. It does not delete or
revert the Keycloak objects created during enablement, and it does not restore a
stock `Trusted Hosts` component that enablement removed. Re-enabling MCP runs
the full reconciliation and verification again. Treat this realm configuration
as durable; disabling MCP or upgrading this chart is not a Keycloak recovery
operation.

With `kcadm.sh` (repeat the block with `C=lifecycle-api-principal-sync` and
`ROLES="view-users query-users"` for the second client):

```bash
REALM=lifecycle
C=lifecycle-api-keycloak-management
ROLES="manage-clients manage-realm"
SECRET=... # the value from the client's Kubernetes Secret

kcadm.sh create clients -r "$REALM" -s clientId="$C" -s protocol=openid-connect \
  -s publicClient=false -s serviceAccountsEnabled=true -s standardFlowEnabled=false \
  -s implicitFlowEnabled=false -s directAccessGrantsEnabled=false \
  -s fullScopeAllowed=false -s secret="$SECRET"

kcadm.sh add-roles -r "$REALM" --uusername "service-account-$C" \
  --cclientid realm-management $(printf -- '--rolename %s ' $ROLES)

CID=$(kcadm.sh get clients -r "$REALM" -q clientId="$C" --fields id --format csv --noquotes)
RMID=$(kcadm.sh get clients -r "$REALM" -q clientId=realm-management --fields id --format csv --noquotes)
for ROLE in $ROLES; do
  R=$(kcadm.sh get "clients/$RMID/roles/$ROLE" -r "$REALM" --fields id,name)
  kcadm.sh create "clients/$CID/scope-mappings/clients/$RMID" -r "$REALM" -b "[$R]"
done
```

The preferred migration path is to let an external secret manager supply the
Kubernetes Secrets (`secrets.apiKeycloakManagement.enabled: false`,
`secrets.apiPrincipalSync.enabled: false`) and use the same secret source when
creating the Keycloak clients. This avoids printing or decoding the
credentials. If the chart-generated Secrets are used instead, the one-time
administrator automation should read them directly from the Kubernetes API
without logging them.

The chart preserves the distinguishing Secret-name suffixes for long release
names and rejects any configuration that resolves both credentials to the same
Secret key. External Secrets may hold both credentials under distinct keys.
Chart-generated credential Secrets use
`helm.sh/resource-policy: keep`, so uninstalling the release does not remove
them. If the Keycloak realm is retained, revoke or delete the matching clients
before deleting the retained Secrets. Rotate a credential by updating its
Keycloak client and Kubernetes Secret as one coordinated operation, then
restart only the owning Lifecycle process (`web` for management, `worker` for
principal sync). `KeycloakRealmImport` is one-shot, so changing a Helm value
alone does not rotate an existing client.

---

## Lifecycle Management & Realm Import

This chart uses the `KeycloakRealmImport` resource for the initial setup.

* **Initial import only:** Changes to the import do not reconcile an existing realm.
* **Existing realms:** Apply required additions through an external Keycloak administration process.
* **Caution:** Deleting the release to force a new import can delete the Keycloak instance and its data, depending on persistence and reclaim-policy settings.

---

### Install the Chart

```shell
helm upgrade -i lifecycle-keycloak \
  oci://ghcr.io/goodrxoss/helm-charts/lifecycle-keycloak \
  --version 0.7.6 \
  -f values.yaml \
  -n lifecycle-keycloak \
  --create-namespace
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| annotations | object | `{}` |  |
| clients.lifecycleApiKeycloakManagement.clientId | string | `"lifecycle-api-keycloak-management"` | Keycloak client ID for the web-only management credential. |
| clients.lifecycleApiKeycloakManagement.clientSecret.secretKeyRef.key | string | `nil` |  |
| clients.lifecycleApiKeycloakManagement.clientSecret.secretKeyRef.name | string | `nil` |  |
| clients.lifecycleApiKeycloakManagement.enabled | bool | `true` | Bootstrap the web-only Lifecycle API Keycloak-management credential. |
| clients.lifecycleApiPrincipalSync.clientId | string | `"lifecycle-api-principal-sync"` | Keycloak client ID for the worker-only principal-sync credential. |
| clients.lifecycleApiPrincipalSync.clientSecret.secretKeyRef.key | string | `nil` |  |
| clients.lifecycleApiPrincipalSync.clientSecret.secretKeyRef.name | string | `nil` |  |
| clients.lifecycleApiPrincipalSync.enabled | bool | `true` | Bootstrap the worker-only read-only principal-sync credential. |
| clients.lifecycleCli.clientId | string | `"lifecycle-cli"` |  |
| clients.lifecycleCli.enabled | bool | `true` |  |
| clients.lifecycleCore.clientId | string | `"lifecycle-core"` |  |
| clients.lifecycleCore.enabled | bool | `true` |  |
| clients.lifecycleUi.clientId | string | `"lifecycle-ui"` |  |
| clients.lifecycleUi.clientSecret.secretKeyRef.key | string | `nil` |  |
| clients.lifecycleUi.clientSecret.secretKeyRef.name | string | `nil` |  |
| clients.lifecycleUi.enabled | bool | `true` |  |
| clients.lifecycleUi.url | string | `"http://localhost:3000"` |  |
| companyIdp.authorizationUrl | string | `nil` |  |
| companyIdp.clientId | string | `nil` |  |
| companyIdp.clientSecret | string | `nil` |  |
| companyIdp.enabled | bool | `true` |  |
| companyIdp.issuer | string | `nil` |  |
| companyIdp.jwksUrl | string | `nil` |  |
| companyIdp.logoutUrl | string | `nil` |  |
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
| githubIdp.defaultScope | string | `"repo user:email"` |  |
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
| internalIdp.internalUrl | string | `nil` |  |
| internalIdp.mapAdminRole | bool | `false` |  |
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
| secrets.apiKeycloakManagement.annotations | object | `{}` |  |
| secrets.apiKeycloakManagement.clientSecret | string | `nil` |  |
| secrets.apiKeycloakManagement.enabled | bool | `true` | Create the lookup-stable Keycloak-management client Secret. |
| secrets.apiKeycloakManagement.fullnameOverride | string | `""` |  |
| secrets.apiPrincipalSync.annotations | object | `{}` |  |
| secrets.apiPrincipalSync.clientSecret | string | `nil` |  |
| secrets.apiPrincipalSync.enabled | bool | `true` | Create the lookup-stable principal-sync client Secret. |
| secrets.apiPrincipalSync.fullnameOverride | string | `""` |  |
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
