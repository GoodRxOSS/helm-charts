# lifecycle-ui

![Version: 0.2.0](https://img.shields.io/badge/Version-0.2.0-informational?style=flat-square)  ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)  ![AppVersion: 0.1.2](https://img.shields.io/badge/AppVersion-0.1.2-informational?style=flat-square)

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
  --version 0.2.0 \
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
| config.annotations | object | `{}` |  |
| config.apiUrl | string | `""` |  |
| config.appUrl | string | `""` |  |
| config.authBaseUrl | string | `""` |  |
| config.authClientId | string | `""` |  |
| config.authRealm | string | `""` |  |
| config.enabled | bool | `true` |  |
| config.fullnameOverride | string | `""` |  |
| deployment.affinity | object | `{}` |  |
| deployment.args | list | `[]` |  |
| deployment.command | list | `[]` |  |
| deployment.envFrom | list | `[]` |  |
| deployment.extraEnv | list | `[]` |  |
| deployment.livenessProbe.failureThreshold | int | `6` |  |
| deployment.livenessProbe.httpGet.path | string | `"/api/health"` |  |
| deployment.livenessProbe.httpGet.port | string | `"http"` |  |
| deployment.livenessProbe.initialDelaySeconds | int | `30` |  |
| deployment.livenessProbe.periodSeconds | int | `10` |  |
| deployment.nodeSelector | object | `{}` |  |
| deployment.readinessProbe.failureThreshold | int | `3` |  |
| deployment.readinessProbe.httpGet.path | string | `"/api/health"` |  |
| deployment.readinessProbe.httpGet.port | string | `"http"` |  |
| deployment.readinessProbe.initialDelaySeconds | int | `5` |  |
| deployment.readinessProbe.periodSeconds | int | `5` |  |
| deployment.replicaCount | int | `1` |  |
| deployment.resources.requests.cpu | string | `"200m"` |  |
| deployment.resources.requests.memory | string | `"256Mi"` |  |
| deployment.startupProbe | object | `{}` |  |
| deployment.tolerations | list | `[]` |  |
| deployment.volumeMounts | list | `[]` |  |
| deployment.volumes | list | `[]` |  |
| extraLabels | object | `{}` |  |
| fullnameOverride | string | `""` |  |
| global.domain | string | `"example.com"` |  |
| global.uiSubDomain | string | `"ui"` |  |
| hpa.enabled | bool | `false` |  |
| hpa.maxReplicas | int | `5` |  |
| hpa.metrics[0].resource.name | string | `"cpu"` |  |
| hpa.metrics[0].resource.target.averageUtilization | int | `80` |  |
| hpa.metrics[0].resource.target.type | string | `"Utilization"` |  |
| hpa.metrics[0].type | string | `"Resource"` |  |
| hpa.minReplicas | int | `1` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.repository | string | `"lifecycleoss/lifecycle-ui"` |  |
| image.tag | string | `"latest"` |  |
| imagePullSecrets | list | `[]` |  |
| ingress.annotations | object | `{}` |  |
| ingress.className | string | `"nginx"` |  |
| ingress.enabled | bool | `true` |  |
| ingress.hosts | list | `[]` |  |
| ingress.tls | list | `[]` |  |
| nameOverride | string | `""` |  |
| pdb.enabled | bool | `false` |  |
| pdb.minAvailable | int | `1` |  |
| podSecurityContext.fsGroup | int | `2000` |  |
| secrets.annotations | object | `{}` |  |
| secrets.authClientSecret | string | `""` |  |
| secrets.authSecret | string | `""` |  |
| secrets.enabled | bool | `true` |  |
| secrets.fullnameOverride | string | `""` |  |
| securityContext.readOnlyRootFilesystem | bool | `false` |  |
| securityContext.runAsNonRoot | bool | `false` |  |
| service.annotations | object | `{}` |  |
| service.enabled | bool | `true` |  |
| service.port | int | `80` |  |
| service.targetPort | int | `3000` |  |
| service.type | string | `"ClusterIP"` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
