# lifecycle-ui

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.1.0](https://img.shields.io/badge/AppVersion-0.1.0-informational?style=flat-square)

A Helm chart for Lifecycle UI (Next.js)

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- Ingress controller (nginx recommended)
- Keycloak instance for authentication
- Lifecycle API backend

## Installation

### Minimal Configuration

Create a `values.yaml` file with your configuration:

```yaml
global:
  domain: YOUR-DOMAIN.com
  uiSubDomain: ui

config:
  nextPublicApiUrl: "https://api.YOUR-DOMAIN.com"
  apiUrl: "https://api.YOUR-DOMAIN.com"
  nextPublicKeycloakBaseUrl: "https://keycloak.YOUR-DOMAIN.com"
  keycloakBaseUrl: "https://keycloak.YOUR-DOMAIN.com"
  nextPublicKeycloakRealm: "lifecycle"
  keycloakRealm: "lifecycle"
  keycloakClientId: "lifecycle-ui"
  keycloakServiceClientId: "lifecycle-ui-service"
```

**Important:** Replace all instances of `YOUR-DOMAIN.com` with your actual domain name.

### Install the Chart

```bash
helm upgrade -i lifecycle-ui \
  oci://ghcr.io/goodrxoss/helm-charts/lifecycle-ui \
  --version 0.1.0 \
  -f values.yaml \
  -n lifecycle-ui \
  --create-namespace
```

### Using a Custom Image

To override the default image:

```yaml
image:
  repository: your-registry/lifecycle-ui
  tag: "1.0.0"
```

### Enabling TLS

To enable TLS with cert-manager:

```yaml
ingress:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt
  tls:
    - secretName: lifecycle-ui-tls
      hosts:
        - ui.YOUR-DOMAIN.com
```

### Enabling Autoscaling

```yaml
hpa:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 80
```

### Custom Resource Limits

```yaml
deployment:
  resources:
    requests:
      cpu: 200m
      memory: 256Mi
    limits:
      cpu: 1000m
      memory: 1Gi
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.domain | string | `"example.com"` | Base domain for the application |
| global.uiSubDomain | string | `"ui"` | Subdomain for UI ingress |
| image.repository | string | `"lifecycleoss/lifecycle-ui"` | Container image repository |
| image.tag | string | `"latest"` | Container image tag |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| imagePullSecrets | list | `[]` | Image pull secrets |
| nameOverride | string | `""` | Override chart name |
| fullnameOverride | string | `""` | Override full release name |
| extraLabels | object | `{}` | Additional labels to add to all resources |
| serviceAccount.create | bool | `true` | Create service account |
| serviceAccount.name | string | `""` | Service account name override |
| serviceAccount.annotations | object | `{}` | Service account annotations |
| podSecurityContext.fsGroup | int | `2000` | Pod security context fsGroup |
| securityContext.readOnlyRootFilesystem | bool | `false` | Read-only root filesystem |
| securityContext.runAsNonRoot | bool | `false` | Run as non-root user |
| deployment.replicaCount | int | `1` | Number of replicas |
| deployment.resources.requests.cpu | string | `"200m"` | CPU request |
| deployment.resources.requests.memory | string | `"256Mi"` | Memory request |
| deployment.livenessProbe | object | HTTP GET /api/health | Liveness probe configuration |
| deployment.readinessProbe | object | HTTP GET /api/health | Readiness probe configuration |
| deployment.startupProbe | object | `{}` | Startup probe configuration |
| deployment.command | list | `[]` | Container command override |
| deployment.args | list | `[]` | Container args override |
| deployment.nodeSelector | object | `{}` | Node selector |
| deployment.tolerations | list | `[]` | Tolerations |
| deployment.affinity | object | `{}` | Affinity rules |
| deployment.extraEnv | list | `[]` | Additional environment variables |
| deployment.envFrom | list | `[]` | Additional envFrom sources |
| deployment.volumes | list | `[]` | Additional volumes |
| deployment.volumeMounts | list | `[]` | Additional volume mounts |
| service.enabled | bool | `true` | Enable service |
| service.type | string | `"ClusterIP"` | Service type |
| service.port | int | `80` | Service port |
| service.targetPort | int | `3000` | Target container port |
| service.annotations | object | `{}` | Service annotations |
| ingress.enabled | bool | `true` | Enable ingress |
| ingress.className | string | `"nginx"` | Ingress class name |
| ingress.annotations | object | `{}` | Ingress annotations |
| ingress.hosts | list | `[]` | Custom ingress hosts (defaults to uiSubDomain.domain) |
| ingress.tls | list | `[]` | TLS configuration |
| hpa.enabled | bool | `false` | Enable HorizontalPodAutoscaler |
| hpa.minReplicas | int | `1` | Minimum replicas |
| hpa.maxReplicas | int | `5` | Maximum replicas |
| hpa.metrics | list | CPU 80% | Autoscaling metrics |
| pdb.enabled | bool | `false` | Enable PodDisruptionBudget |
| pdb.minAvailable | int | `1` | Minimum available pods |
| pdb.maxUnavailable | int | - | Maximum unavailable pods (use either this or minAvailable) |
| secrets.enabled | bool | `true` | Enable secrets creation |
| secrets.fullnameOverride | string | `""` | Secret name override |
| secrets.annotations | object | `{}` | Secret annotations |
| secrets.nextauthSecret | string | `""` | NextAuth JWT secret (auto-generated if empty) |
| secrets.keycloakClientSecret | string | `""` | Keycloak client secret (auto-generated if empty) |
| secrets.keycloakServiceClientSecret | string | `""` | Keycloak service client secret (auto-generated if empty) |
| config.enabled | bool | `true` | Enable configmap creation |
| config.fullnameOverride | string | `""` | ConfigMap name override |
| config.annotations | object | `{}` | ConfigMap annotations |
| config.nextPublicAppUrl | string | `""` | Public app URL (defaults to https://uiSubDomain.domain) |
| config.appUrl | string | `""` | App URL (defaults to https://uiSubDomain.domain) |
| config.nextauthUrl | string | `""` | NextAuth URL (defaults to https://uiSubDomain.domain) |
| config.nextPublicApiUrl | string | `""` | Public API URL |
| config.apiUrl | string | `""` | API URL |
| config.nextPublicKeycloakBaseUrl | string | `""` | Public Keycloak base URL |
| config.keycloakBaseUrl | string | `""` | Keycloak base URL |
| config.nextPublicKeycloakRealm | string | `""` | Public Keycloak realm |
| config.keycloakRealm | string | `""` | Keycloak realm |
| config.keycloakClientId | string | `""` | Keycloak client ID |
| config.keycloakServiceClientId | string | `""` | Keycloak service client ID |
