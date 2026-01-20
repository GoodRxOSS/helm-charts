# keycloak-operator

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square)  ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)  ![AppVersion: 26.4.7](https://img.shields.io/badge/AppVersion-26.4.7-informational?style=flat-square)

Helm chart for Keycloak operator based on the [official manifests](https://www.keycloak.org/operator/installation#_installing_by_using_kubectl_without_operator_lifecycle_manager)

## Installation

### Prerequisites

You may want to override the `keycloak-operator` container image tag and/or the `keycloak` image tag. You should also specify a custom namespace where the operator will watch for Keycloak Custom Resources (CRs); ensure this namespace exists before installation. To do this, create a minimal `values.yaml` file with your configuration:

```yaml
keycloak:
  image:
    tag: "26.4.7"

image:
  tag: "26.4.7"

watchNamespaces:
  - keycloak
  - my-app
```

**Important:** A new version of the `keycloak-operator` service may require a new Custom Resource Definition (CRD). Since the CRD is part of this Helm chart, it must be updated during the installation.

### Install the Chart

```shell
helm upgrade -i keycloak-operator \
  oci://ghcr.io/goodrxoss/helm-charts/keycloak-operator \
  --version 0.1.0 \
  -f values.yaml \
  -n keycloak-operator \
  --create-namespace
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| container.args | list | `[]` |  |
| container.command | list | `[]` |  |
| deployment.annotations | object | `{}` |  |
| deployment.extraLabels | object | `{}` |  |
| env | object | `{}` |  |
| envFrom | object | `{}` |  |
| extraEnv | list | `[]` |  |
| extraLabels | object | `{}` |  |
| fullnameOverride | string | `""` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.repository | string | `"quay.io/keycloak/keycloak-operator"` |  |
| image.tag | string | `""` |  |
| imagePullSecrets | list | `[]` |  |
| keycloak.image.pullPolicy | string | `"IfNotPresent"` |  |
| keycloak.image.repository | string | `"quay.io/keycloak/keycloak"` |  |
| keycloak.image.tag | string | `""` |  |
| livenessProbe.failureThreshold | int | `3` |  |
| livenessProbe.httpGet.path | string | `"/q/health/live"` |  |
| livenessProbe.httpGet.port | int | `8080` |  |
| livenessProbe.httpGet.scheme | string | `"HTTP"` |  |
| livenessProbe.initialDelaySeconds | int | `5` |  |
| livenessProbe.periodSeconds | int | `10` |  |
| livenessProbe.successThreshold | int | `1` |  |
| livenessProbe.timeoutSeconds | int | `10` |  |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` |  |
| podAnnotations | object | `{}` |  |
| podSecurityContext.fsGroup | int | `2000` |  |
| ports[0].containerPort | int | `8080` |  |
| ports[0].name | string | `"http"` |  |
| ports[0].protocol | string | `"TCP"` |  |
| rbac.create | bool | `true` |  |
| readinessProbe.failureThreshold | int | `3` |  |
| readinessProbe.httpGet.path | string | `"/q/health/ready"` |  |
| readinessProbe.httpGet.port | int | `8080` |  |
| readinessProbe.httpGet.scheme | string | `"HTTP"` |  |
| readinessProbe.initialDelaySeconds | int | `5` |  |
| readinessProbe.periodSeconds | int | `10` |  |
| readinessProbe.successThreshold | int | `1` |  |
| readinessProbe.timeoutSeconds | int | `10` |  |
| replicaCount | int | `1` |  |
| resources.limits.cpu | string | `"700m"` |  |
| resources.limits.memory | string | `"450Mi"` |  |
| resources.requests.cpu | string | `"300m"` |  |
| resources.requests.memory | string | `"450Mi"` |  |
| securityContext.readOnlyRootFilesystem | bool | `false` |  |
| securityContext.runAsNonRoot | bool | `false` |  |
| service.port | int | `80` |  |
| service.type | string | `"ClusterIP"` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
| startupProbe.failureThreshold | int | `3` |  |
| startupProbe.httpGet.path | string | `"/q/health/started"` |  |
| startupProbe.httpGet.port | int | `8080` |  |
| startupProbe.httpGet.scheme | string | `"HTTP"` |  |
| startupProbe.initialDelaySeconds | int | `5` |  |
| startupProbe.periodSeconds | int | `10` |  |
| startupProbe.successThreshold | int | `1` |  |
| startupProbe.timeoutSeconds | int | `10` |  |
| tolerations | list | `[]` |  |
| volumeMounts | list | `[]` |  |
| volumes | list | `[]` |  |
| watchNamespaces | string | `nil` |  |