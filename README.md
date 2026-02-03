# <img src="./assets/logo.svg" style="height:32px; width:auto; vertical-align:middle;"> Lifecycle Helm Charts Repository

A collection of Helm charts primarily used for **Lifecycle** application deployment.

## 📚 Available Charts:

| Chart | Version | App Version | Description |
| :--- | :--- | :--- | :--- |
| [keycloak-operator](./charts/keycloak-operator) | `0.1.0` | `26.4.7` | Helm chart for Keycloak operator based on the [official manifests](https://www.keycloak.org/operator/installation#_installing_by_using_kubectl_without_operator_lifecycle_manager) |
| [lifecycle](./charts/lifecycle) | `0.3.3` | `0.1.3` | A Helm umbrella chart for full Lifecycle stack |
| [lifecycle-keycloak](./charts/lifecycle-keycloak) | `0.2.0` | `0.0.0` | Keycloak instance for Lifecycle stack with automated Operator-driven setup and imports |
| [lifecycle-ui](./charts/lifecycle-ui) | `0.1.1` | `0.1.1` | A Helm chart for Lifecycle UI (Next.js) |
