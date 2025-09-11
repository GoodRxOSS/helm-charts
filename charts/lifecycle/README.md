# lifecycle

![Version: 0.3.3](https://img.shields.io/badge/Version-0.3.3-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.1.3](https://img.shields.io/badge/AppVersion-0.1.3-informational?style=flat-square)

A Helm umbrella chart for full Lifecycle stack

## Installation

### Prerequisites

Create a minimal `values.yaml` file with your domain configuration:

```yaml
global:
  domain: YOUR-DOMAIN.com  # CHANGE THIS to your actual domain
  image:
    tag: 0.1.3

distribution:
  ingress:
    hostname: distribution.YOUR-DOMAIN.com  # CHANGE THIS to match your domain

buildkit:
  buildkitdToml: |
    debug = true
    [registry."distribution.YOUR-DOMAIN.com"]  # CHANGE THIS to match your domain
      http = true
      insecure = true
    [worker.oci]
      platforms = [ "linux/amd64" ]
      reservedSpace = "60%"
      maxUsedSpace = "80%"
      max-parallelism = 25
```

**Important:** Replace all instances of `YOUR-DOMAIN.com` with your actual domain name.

### Install the Chart

```bash
helm upgrade -i lifecycle \
  oci://ghcr.io/goodrxoss/helm-charts/lifecycle \
  --version 0.3.3 \
  -f values.yaml \
  -n lifecycle-app \
  --create-namespace
```

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| <https://andrcuns.github.io/charts> | buildkit(buildkit-service) | 0.10.0 |
| <https://charts.bitnami.com/bitnami> | postgres(postgresql) | 15.5.19 |
| <https://charts.bitnami.com/bitnami> | redis(redis) | 19.6.3 |
| <https://jouve.github.io/charts> | distribution(distribution) | 0.1.7 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| buildkit.buildkitdToml | string | `"debug = true\n[registry.\"distribution.example.com\"]\n  http = true\n  insecure = true\n[worker.oci]\n  platforms = [ \"linux/amd64\" ]\n  reservedSpace = \"60%\"\n  maxUsedSpace = \"80%\"\n  max-parallelism = 25\n"` |  |
| buildkit.enabled | bool | `true` |  |
| buildkit.fullnameOverride | string | `""` |  |
| buildkit.resources.requests.cpu | string | `"500m"` |  |
| buildkit.resources.requests.memory | string | `"1Gi"` |  |
| components.web.container.args | list | `[]` |  |
| components.web.container.command | list | `[]` |  |
| components.web.deployment.affinity | object | `{}` |  |
| components.web.deployment.envFrom | object | `{}` |  |
| components.web.deployment.extraEnv[0].name | string | `"LIFECYCLE_MODE"` |  |
| components.web.deployment.extraEnv[0].value | string | `"web"` |  |
| components.web.deployment.livenessProbe.failureThreshold | int | `6` |  |
| components.web.deployment.livenessProbe.httpGet.path | string | `"/api/health"` |  |
| components.web.deployment.livenessProbe.httpGet.port | string | `"http"` |  |
| components.web.deployment.livenessProbe.initialDelaySeconds | int | `60` |  |
| components.web.deployment.livenessProbe.periodSeconds | int | `10` |  |
| components.web.deployment.nodeSelector | object | `{}` |  |
| components.web.deployment.ports[0].containerPort | int | `80` |  |
| components.web.deployment.ports[0].name | string | `"http"` |  |
| components.web.deployment.ports[0].protocol | string | `"TCP"` |  |
| components.web.deployment.readinessProbe.failureThreshold | int | `3` |  |
| components.web.deployment.readinessProbe.httpGet.path | string | `"/api/health"` |  |
| components.web.deployment.readinessProbe.httpGet.port | string | `"http"` |  |
| components.web.deployment.readinessProbe.periodSeconds | int | `5` |  |
| components.web.deployment.replicaCount | int | `1` |  |
| components.web.deployment.resources.requests.cpu | string | `"200m"` |  |
| components.web.deployment.resources.requests.memory | string | `"200Mi"` |  |
| components.web.deployment.startupProbe | object | `{}` |  |
| components.web.deployment.tolerations | list | `[]` |  |
| components.web.deployment.volumeMounts | list | `[]` |  |
| components.web.deployment.volumes | list | `[]` |  |
| components.web.enabled | bool | `true` |  |
| components.web.extraLabels | object | `{}` |  |
| components.web.fullnameOverride | string | `""` |  |
| components.web.ingress.annotations."cert-manager.io/cluster-issuer" | string | `"letsencrypt"` |  |
| components.web.ingress.defaultBackend | object | `{}` |  |
| components.web.ingress.enabled | bool | `true` |  |
| components.web.ingress.hosts | list | `[]` |  |
| components.web.ingress.ingressClassName | string | `"nginx"` |  |
| components.web.service.enabled | bool | `true` |  |
| components.web.service.port | int | `80` |  |
| components.web.service.targetPort | int | `80` |  |
| components.web.service.type | string | `"ClusterIP"` |  |
| components.worker.container.args | list | `[]` |  |
| components.worker.container.command | list | `[]` |  |
| components.worker.deployment.affinity | object | `{}` |  |
| components.worker.deployment.envFrom | object | `{}` |  |
| components.worker.deployment.extraEnv[0].name | string | `"LIFECYCLE_MODE"` |  |
| components.worker.deployment.extraEnv[0].value | string | `"job"` |  |
| components.worker.deployment.extraEnv[1].name | string | `"STAGE"` |  |
| components.worker.deployment.extraEnv[1].value | string | `"prod"` |  |
| components.worker.deployment.extraEnv[2].name | string | `"LOG_LEVEL"` |  |
| components.worker.deployment.extraEnv[2].value | string | `"info"` |  |
| components.worker.deployment.extraEnv[3].name | string | `"MAX_GITHUB_API_REQUEST"` |  |
| components.worker.deployment.extraEnv[3].value | string | `"33"` |  |
| components.worker.deployment.extraEnv[4].name | string | `"GITHUB_API_REQUEST_INTERVAL"` |  |
| components.worker.deployment.extraEnv[4].value | string | `"10000"` |  |
| components.worker.deployment.livenessProbe.failureThreshold | int | `12` |  |
| components.worker.deployment.livenessProbe.httpGet.path | string | `"/api/health"` |  |
| components.worker.deployment.livenessProbe.httpGet.port | string | `"http"` |  |
| components.worker.deployment.livenessProbe.initialDelaySeconds | int | `60` |  |
| components.worker.deployment.livenessProbe.periodSeconds | int | `10` |  |
| components.worker.deployment.livenessProbe.timeoutSeconds | int | `10` |  |
| components.worker.deployment.nodeSelector | object | `{}` |  |
| components.worker.deployment.ports[0].containerPort | int | `80` |  |
| components.worker.deployment.ports[0].name | string | `"http"` |  |
| components.worker.deployment.ports[0].protocol | string | `"TCP"` |  |
| components.worker.deployment.readinessProbe.failureThreshold | int | `3` |  |
| components.worker.deployment.readinessProbe.httpGet.path | string | `"/api/jobs"` |  |
| components.worker.deployment.readinessProbe.httpGet.port | string | `"http"` |  |
| components.worker.deployment.readinessProbe.periodSeconds | int | `5` |  |
| components.worker.deployment.replicaCount | int | `1` |  |
| components.worker.deployment.resources.limits.cpu | string | `"1000m"` |  |
| components.worker.deployment.resources.limits.memory | string | `"4000Mi"` |  |
| components.worker.deployment.resources.requests.cpu | string | `"200m"` |  |
| components.worker.deployment.resources.requests.memory | string | `"200Mi"` |  |
| components.worker.deployment.startupProbe | object | `{}` |  |
| components.worker.deployment.tolerations | list | `[]` |  |
| components.worker.deployment.volumeMounts | list | `[]` |  |
| components.worker.deployment.volumes | list | `[]` |  |
| components.worker.enabled | bool | `true` |  |
| components.worker.extraLabels | object | `{}` |  |
| components.worker.fullnameOverride | string | `""` |  |
| components.worker.hpa.enabled | bool | `false` |  |
| components.worker.hpa.maxReplicas | int | `5` |  |
| components.worker.hpa.metrics[0].resource.name | string | `"cpu"` |  |
| components.worker.hpa.metrics[0].resource.target.averageUtilization | int | `80` |  |
| components.worker.hpa.metrics[0].resource.target.type | string | `"Utilization"` |  |
| components.worker.hpa.metrics[0].type | string | `"Resource"` |  |
| components.worker.hpa.minReplicas | int | `1` |  |
| components.worker.ingress.enabled | bool | `false` |  |
| components.worker.networkPolicy.egress | list | `[]` |  |
| components.worker.networkPolicy.enabled | bool | `false` |  |
| components.worker.networkPolicy.ingress | list | `[]` |  |
| components.worker.pdb.enabled | bool | `false` |  |
| components.worker.pdb.minAvailable | int | `1` |  |
| components.worker.service.clusterIP | string | `""` |  |
| components.worker.service.enabled | bool | `false` |  |
| components.worker.service.externalTrafficPolicy | string | `""` |  |
| config.annotations | list | `[]` |  |
| config.enabled | bool | `true` |  |
| config.fullnameOverride | string | `""` |  |
| distribution.enabled | bool | `true` |  |
| distribution.image.tag | string | `"2.8.3"` |  |
| distribution.ingress.annotations."nginx.ingress.kubernetes.io/proxy-body-size" | string | `"0"` |  |
| distribution.ingress.enabled | bool | `true` |  |
| distribution.ingress.hostname | string | `"distribution.example.com"` |  |
| distribution.ingress.ingressClassName | string | `"nginx"` |  |
| distribution.persistence.enabled | bool | `true` |  |
| distribution.persistence.size | string | `"20Gi"` |  |
| global.appSubDomain | string | `"app"` |  |
| global.domain | string | `"example.com"` |  |
| global.envFrom | object | `{}` |  |
| global.env[0].name | string | `"JOB_VERSION"` |  |
| global.env[0].value | string | `"default"` |  |
| global.env[1].name | string | `"ENVIRONMENT"` |  |
| global.env[1].value | string | `"production"` |  |
| global.env[2].name | string | `"NODE_ENV"` |  |
| global.env[2].value | string | `"production"` |  |
| global.env[3].name | string | `"APP_ENV"` |  |
| global.env[3].value | string | `"production"` |  |
| global.env[4].name | string | `"PINO_PRETTY"` |  |
| global.env[4].value | string | `"false"` |  |
| global.env[5].name | string | `"PORT"` |  |
| global.env[5].value | string | `"80"` |  |
| global.extraEnv | list | `[]` |  |
| global.extraLabels | object | `{}` |  |
| global.image.pullPolicy | string | `"IfNotPresent"` |  |
| global.image.repository | string | `"lifecycleoss/app"` |  |
| global.image.tag | string | `""` |  |
| global.imagePullSecrets | list | `[]` |  |
| global.podSecurityContext.fsGroup | int | `2000` |  |
| global.scope | string | `"core"` |  |
| global.securityContext.readOnlyRootFilesystem | bool | `false` |  |
| global.securityContext.runAsNonRoot | bool | `false` |  |
| global.serviceAccount.annotations | list | `[]` |  |
| global.serviceAccount.create | bool | `true` |  |
| global.serviceAccount.name | string | `""` |  |
| postgres.auth.database | string | `"lifecycle"` |  |
| postgres.auth.existingSecret | string | `"{{ include \"..helper.postgresSecretName\" . }}"` |  |
| postgres.auth.secretKeys.adminPasswordKey | string | `"POSTGRES_ADMIN_PASSWORD"` |  |
| postgres.auth.secretKeys.userPasswordKey | string | `"POSTGRES_USER_PASSWORD"` |  |
| postgres.auth.username | string | `"lifecycle"` |  |
| postgres.enabled | bool | `true` |  |
| postgres.fullnameOverride | string | `""` |  |
| postgres.image.repository | string | `"bitnamilegacy/postgresql"` |  |
| postgres.primary.persistence.enabled | bool | `true` |  |
| postgres.primary.persistence.size | string | `"11Gi"` |  |
| rbac.create | bool | `true` |  |
| redis.architecture | string | `"standalone"` |  |
| redis.auth.enabled | bool | `true` |  |
| redis.auth.existingSecret | string | `"{{ include \"..helper.redisSecretName\" . }}"` |  |
| redis.auth.existingSecretPasswordKey | string | `"REDIS_PASSWORD"` |  |
| redis.auth.password | string | `"password"` |  |
| redis.enabled | bool | `true` |  |
| redis.fullnameOverride | string | `""` |  |
| redis.image.repository | string | `"bitnamilegacy/redis"` |  |
| redis.master.persistence.enabled | bool | `true` |  |
| redis.master.persistence.size | string | `"8Gi"` |  |
| secrets.bootstrap.annotations | list | `[]` |  |
| secrets.bootstrap.enabled | bool | `true` |  |
| secrets.bootstrap.fullnameOverride | string | `""` |  |
| secrets.bootstrap.githubAppId | string | `""` |  |
| secrets.bootstrap.githubClientId | string | `""` |  |
| secrets.bootstrap.githubClientSecret | string | `""` |  |
| secrets.bootstrap.githubInstallationId | string | `""` |  |
| secrets.bootstrap.githubPrivateKey | string | `""` |  |
| secrets.bootstrap.githubWebhookSecret | string | `""` |  |
| secrets.common.annotations | list | `[]` |  |
| secrets.common.enabled | bool | `true` |  |
| secrets.common.fullnameOverride | string | `""` |  |
| secrets.postgres.annotations | list | `[]` |  |
| secrets.postgres.enabled | bool | `true` |  |
| secrets.postgres.fullnameOverride | string | `""` |  |
| secrets.postgres.postgresAdminPassword | string | `""` |  |
| secrets.postgres.postgresUserPassword | string | `""` |  |
| secrets.redis.annotations | list | `[]` |  |
| secrets.redis.enabled | bool | `true` |  |
| secrets.redis.fullnameOverride | string | `""` |  |
| secrets.redis.redisPassword | string | `""` |  |
