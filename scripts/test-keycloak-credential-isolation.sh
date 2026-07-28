#!/usr/bin/env bash

# Copyright 2026 GoodRx, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
scratch_root=$(mktemp -d)
trap 'rm -rf -- "$scratch_root"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

repeat_a() {
  local length=$1
  local value
  printf -v value '%*s' "$length" ''
  printf '%s' "${value// /a}"
}

trim_yaml_scalar() {
  local value=$1
  value=${value#\"}
  value=${value%\"}
  printf '%s' "$value"
}

source_metadata_name() {
  local source=$1
  awk -v marker="# Source: ${source}" '
    $0 == marker { in_source = 1; next }
    in_source && /^---$/ { exit }
    in_source && /^  name:/ { print $2; exit }
  '
}

placeholder_secret_name() {
  local placeholder=$1
  awk -v placeholder="${placeholder}:" '
    index($0, placeholder) { in_placeholder = 1; next }
    in_placeholder && $1 == "name:" { print $2; exit }
  '
}

assert_distinct_suffixes() {
  local context=$1
  local management_name=$2
  local principal_sync_name=$3

  [[ "$management_name" != "$principal_sync_name" ]] ||
    fail "${context}: credential Secret names collided at ${management_name}"
  [[ "$management_name" == *-api-keycloak-management ]] ||
    fail "${context}: management suffix was not preserved: ${management_name}"
  [[ "$principal_sync_name" == *-api-principal-sync ]] ||
    fail "${context}: principal-sync suffix was not preserved: ${principal_sync_name}"
  ((${#management_name} <= 63)) ||
    fail "${context}: management Secret name exceeds 63 characters"
  ((${#principal_sync_name} <= 63)) ||
    fail "${context}: principal-sync Secret name exceeds 63 characters"
}

standalone_chart="$scratch_root/lifecycle-keycloak"
mkdir -p "$standalone_chart"
cp "$repo_root/charts/lifecycle-keycloak/values.yaml" "$standalone_chart/values.yaml"
cp -R "$repo_root/charts/lifecycle-keycloak/templates" "$standalone_chart/templates"

cat >"$standalone_chart/Chart.yaml" <<'EOF'
apiVersion: v2
name: lifecycle-keycloak
description: Minimal dependency-free chart for credential isolation regression tests
type: application
version: 0.0.0-test
appVersion: 0.0.0-test
EOF

render_standalone() {
  local release_name=$1
  shift
  helm template "$release_name" "$standalone_chart" \
    --api-versions k8s.keycloak.org/v2alpha1 \
    --set-string secrets.githubIdp.clientId=test-client \
    --set-string secrets.githubIdp.clientSecret=test-secret \
    "$@"
}

for release_length in 38 39 53; do
  release_name=$(repeat_a "$release_length")
  rendered=$(render_standalone "$release_name")

  management_name=$(trim_yaml_scalar "$(
    printf '%s\n' "$rendered" |
      source_metadata_name "lifecycle-keycloak/templates/api-keycloak-management-secret.yaml"
  )")
  principal_sync_name=$(trim_yaml_scalar "$(
    printf '%s\n' "$rendered" |
      source_metadata_name "lifecycle-keycloak/templates/api-principal-sync-secret.yaml"
  )")
  assert_distinct_suffixes \
    "standalone release length ${release_length}" \
    "$management_name" \
    "$principal_sync_name"

  management_placeholder=$(trim_yaml_scalar "$(
    printf '%s\n' "$rendered" |
      placeholder_secret_name "LIFECYCLE_API_KEYCLOAK_MANAGEMENT_CLIENT_SECRET"
  )")
  principal_sync_placeholder=$(trim_yaml_scalar "$(
    printf '%s\n' "$rendered" |
      placeholder_secret_name "LIFECYCLE_API_PRINCIPAL_SYNC_CLIENT_SECRET"
  )")
  [[ "$management_placeholder" == "$management_name" ]] ||
    fail "standalone release length ${release_length}: management placeholder references ${management_placeholder}"
  [[ "$principal_sync_placeholder" == "$principal_sync_name" ]] ||
    fail "standalone release length ${release_length}: principal-sync placeholder references ${principal_sync_placeholder}"
done

if render_standalone collision-check \
  --set-string clients.lifecycleApiKeycloakManagement.clientSecret.secretKeyRef.name=shared-api-credential \
  --set-string clients.lifecycleApiPrincipalSync.clientSecret.secretKeyRef.name=shared-api-credential \
  >/dev/null 2>&1; then
  fail "standalone chart accepted one Secret identity for both API credentials"
fi

render_standalone shared-secret-distinct-keys \
  --set-string clients.lifecycleApiKeycloakManagement.clientSecret.secretKeyRef.name=shared-api-credential \
  --set-string clients.lifecycleApiKeycloakManagement.clientSecret.secretKeyRef.key=managementSecret \
  --set-string clients.lifecycleApiPrincipalSync.clientSecret.secretKeyRef.name=shared-api-credential \
  --set-string clients.lifecycleApiPrincipalSync.clientSecret.secretKeyRef.key=principalSyncSecret \
  >/dev/null

printf 'Keycloak credential Secret isolation render tests passed.\n'
