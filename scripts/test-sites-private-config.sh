#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
scratch_root=$(mktemp -d)
trap 'rm -rf -- "$scratch_root"' EXIT
# Exercise owned templates, including the bundled UI, without remote dependencies.
mkdir -p "$scratch_root/lifecycle/charts"
cp "$repo_root/charts/lifecycle/values.yaml" "$scratch_root/lifecycle/values.yaml"
cp -R "$repo_root/charts/lifecycle/templates" "$scratch_root/lifecycle/templates"
cp -R "$repo_root/charts/lifecycle-ui" "$scratch_root/lifecycle/charts/lifecycle-ui"
cat > "$scratch_root/lifecycle/Chart.yaml" <<'CHART'
apiVersion: v2
name: lifecycle
type: application
version: 0.0.0-test
appVersion: 0.0.0-test
dependencies:
  - name: lifecycle-ui
    alias: ui
    version: 0.3.6
    condition: ui.enabled
CHART
render() { helm template sites "$scratch_root/lifecycle" --set components.gateway.enabled=true "$@"; }
count() { awk -v pattern="$2" 'index($0, pattern) { n++ } END { print n+0 }' "$1"; }
expect_fail() {
  local message=$1
  shift
  if render "$@" > /dev/null 2> "$scratch_root/error"; then
    echo "FAIL: unsafe configuration unexpectedly rendered: $message" >&2
    exit 1
  fi
  grep -F "$message" "$scratch_root/error" > /dev/null
}
for enabled in true false; do
  render --set "sitesPrivate.enabled=$enabled" > "$scratch_root/core-$enabled.yaml"
  # Shared read-only status credentials stay present with private access off.
  test "$(count "$scratch_root/core-$enabled.yaml" 'name: KEYCLOAK_PRINCIPAL_SYNC_CLIENT_SECRET')" = 3
  test "$(count "$scratch_root/core-$enabled.yaml" 'name: "sites-keycloak-api-principal-sync"')" = 3
  test "$(count "$scratch_root/core-$enabled.yaml" 'name: KEYCLOAK_MANAGEMENT_CLIENT_SECRET')" = 1
  test "$(count "$scratch_root/core-$enabled.yaml" 'name: SITES_UI_ORIGIN')" = 2
  test "$(count "$scratch_root/core-$enabled.yaml" 'NEXTAUTH_URL: "https://ui.example.com"')" = 1
  test "$(count "$scratch_root/core-$enabled.yaml" 'value: "https://ui.example.com"')" = 2
  if grep -Eq 'SITES_BROWSER_BRIDGE_SECRET|SITES_UI_OAUTH_CLIENT_ID|SITES_API_INTERNAL_URL|SITES_GATEWAY_HTTPS|sites-directory' "$scratch_root/core-$enabled.yaml"; then
    echo 'FAIL: obsolete Sites configuration rendered' >&2
    exit 1
  fi
done
test "$(count "$scratch_root/core-false.yaml" 'name: SITES_PRIVATE_ENABLED')" = 0
test "$(count "$scratch_root/core-true.yaml" 'name: SITES_PRIVATE_ENABLED')" = 2
render --set sitesPrivate.enabled=true --set ui.config.appUrl=https://reader.example.org --set ui.config.apiUrl=https://api.example.org \
  --set keycloak.clients.lifecycleApiPrincipalSync.clientId=read-only-status \
  --set keycloak.clients.lifecycleApiPrincipalSync.clientSecret.secretKeyRef.name=external-status \
  --set keycloak.clients.lifecycleApiPrincipalSync.clientSecret.secretKeyRef.key=statusSecret > "$scratch_root/overrides.yaml"
for pattern in 'value: "read-only-status"' 'name: "external-status"' 'key: "statusSecret"'; do
  test "$(count "$scratch_root/overrides.yaml" "$pattern")" = 3
done
test "$(count "$scratch_root/overrides.yaml" 'value: "https://reader.example.org"')" = 2
test "$(count "$scratch_root/overrides.yaml" 'NEXTAUTH_URL: "https://reader.example.org"')" = 1
test "$(count "$scratch_root/overrides.yaml" 'NEXT_PUBLIC_API_URL: "https://api.example.org"')" = 1
render --set sitesPrivate.enabled=true --set ui.config.appUrl=https://reader.example.org/ > "$scratch_root/trailing-slash.yaml"
test "$(count "$scratch_root/trailing-slash.yaml" 'value: "https://reader.example.org"')" = 2
test "$(count "$scratch_root/trailing-slash.yaml" 'NEXTAUTH_URL: "https://reader.example.org/"')" = 1
render --set sitesPrivate.enabled=true --set ui.config.appUrl=https://READER.example.org:443/app > "$scratch_root/canonical.yaml"
test "$(count "$scratch_root/canonical.yaml" 'value: "https://reader.example.org"')" = 2
render --set sitesPrivate.enabled=true --set global.uiSubDomain=reader --set global.domain=example.org > "$scratch_root/domain.yaml"
test "$(count "$scratch_root/domain.yaml" 'value: "https://reader.example.org"')" = 2
test "$(count "$scratch_root/domain.yaml" 'NEXTAUTH_URL: "https://reader.example.org"')" = 1
render --set sitesPrivate.enabled=true --set ui.enabled=false --set sitesPrivate.uiOrigin=https://standalone.example.org > "$scratch_root/standalone-core.yaml"
test "$(count "$scratch_root/standalone-core.yaml" 'value: "https://standalone.example.org"')" = 2
helm template sites "$repo_root/charts/lifecycle-ui" --set config.appUrl=https://standalone.example.org --set config.apiUrl=https://api.example.org > "$scratch_root/standalone-ui.yaml"
test "$(count "$scratch_root/standalone-ui.yaml" 'NEXTAUTH_URL: "https://standalone.example.org"')" = 1
test "$(count "$scratch_root/standalone-ui.yaml" 'NEXT_PUBLIC_API_URL: "https://api.example.org"')" = 1
test "$(count "$scratch_root/standalone-ui.yaml" 'SITES_')" = 0
# External identity providers use the existing explicit env/Secret configuration.
render --set keycloak.enabled=false > "$scratch_root/external.yaml"
test "$(count "$scratch_root/external.yaml" 'name: KEYCLOAK_PRINCIPAL_SYNC_CLIENT_SECRET')" = 0
render --set keycloak.clients.lifecycleApiPrincipalSync.enabled=false > "$scratch_root/no-status.yaml"
test "$(count "$scratch_root/no-status.yaml" 'name: KEYCLOAK_PRINCIPAL_SYNC_CLIENT_SECRET')" = 0
render --set sitesPrivate.enabled=false --set ui.config.appUrl=http://localhost:3000 > "$scratch_root/http-ui-disabled.yaml"
test "$(count "$scratch_root/http-ui-disabled.yaml" 'name: SITES_UI_ORIGIN')" = 0
test "$(count "$scratch_root/http-ui-disabled.yaml" 'NEXTAUTH_URL: "http://localhost:3000"')" = 1
expect_fail 'must be a canonical HTTPS origin' --set sitesPrivate.enabled=true --set sitesPrivate.uiOrigin=https://reader.example.org/
expect_fail 'must be a canonical HTTPS origin' --set sitesPrivate.uiOrigin=http://reader.example.org
expect_fail 'must be an HTTPS URL without credentials' --set sitesPrivate.enabled=true --set ui.config.appUrl=https://user:password@reader.example.org
expect_fail 'authorization-capable gateway' --set sitesPrivate.enabled=true --set components.gateway.enabled=false
expect_fail 'uiOrigin is required' --set sitesPrivate.enabled=true --set ui.enabled=false
expect_fail 'requires the read-only' --set sitesPrivate.enabled=true --set keycloak.clients.lifecycleApiPrincipalSync.enabled=false
expect_fail 'lifecycleApiPrincipalSync.clientId is required' --set keycloak.clients.lifecycleApiPrincipalSync.clientId=
echo 'Sites configuration: shared read-only credentials, rollback, canonical UI routing and required settings passed (owned templates only).'
