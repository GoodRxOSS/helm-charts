#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
scratch_root=$(mktemp -d)
trap 'rm -rf -- "$scratch_root"' EXIT
# Exercise our owned templates without downloading/rendering unrelated dependencies.
mkdir -p "$scratch_root/lifecycle"
cp "$repo_root/charts/lifecycle/values.yaml" "$scratch_root/lifecycle/values.yaml"
cp -R "$repo_root/charts/lifecycle/templates" "$scratch_root/lifecycle/templates"
cat > "$scratch_root/lifecycle/Chart.yaml" <<'CHART'
apiVersion: v2
name: lifecycle
type: application
version: 0.0.0-test
appVersion: 0.0.0-test
CHART
common=(--set sitesPrivate.uiOAuthClientId=lifecycle-ui --set components.gateway.enabled=true --set sitesPrivate.uiOrigin=https://ui.example.com --set sitesPrivate.bridgeSecret.name=sites-bridge --set sitesPrivate.directory.secretName=sites-directory)
for enabled in true false; do
  helm template sites "$scratch_root/lifecycle" "${common[@]}" --set "sitesPrivate.enabled=$enabled" > "$scratch_root/core-$enabled.yaml"
  helm template sites "$repo_root/charts/lifecycle-ui" --set "sitesPrivate.enabled=$enabled" --set sitesPrivate.uiOrigin=https://ui.example.com --set sitesPrivate.bridgeSecret.name=sites-bridge > "$scratch_root/ui-$enabled.yaml"
done
count() { awk -v pattern="$2" 'index($0, pattern) { n++ } END { print n+0 }' "$1"; }
for enabled in true false; do
  test "$(count "$scratch_root/core-$enabled.yaml" 'name: SITES_UI_OAUTH_CLIENT_ID')" = 2
  test "$(count "$scratch_root/core-$enabled.yaml" 'name: "sites-directory"')" = 2
  test "$(count "$scratch_root/core-$enabled.yaml" 'name: "sites-bridge"')" = 2
  test "$(count "$scratch_root/ui-$enabled.yaml" 'name: "sites-bridge"')" = 1
done
test "$(count "$scratch_root/core-false.yaml" 'name: SITES_PRIVATE_ENABLED')" = 0
test "$(count "$scratch_root/ui-false.yaml" 'name: SITES_PRIVATE_ENABLED')" = 0
test "$(count "$scratch_root/core-true.yaml" 'name: SITES_PRIVATE_ENABLED')" = 2
if helm template sites "$scratch_root/lifecycle" --set sitesPrivate.enabled=true > /dev/null 2>&1; then
  echo 'FAIL: unsafe enabled configuration unexpectedly rendered' >&2
  exit 1
fi
if helm template sites "$scratch_root/lifecycle" "${common[@]}" --set sitesPrivate.enabled=true --set sitesPrivate.uiOAuthClientId= > /dev/null 2>&1; then
  echo 'FAIL: enabled configuration without the UI OAuth client unexpectedly rendered' >&2
  exit 1
fi
echo 'Sites configuration: enabled/disabled credential retention and required fields passed (owned templates only).'
