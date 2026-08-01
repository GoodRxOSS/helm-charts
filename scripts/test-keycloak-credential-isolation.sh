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

configmap_data_value() {
  local key=$1
  awk -v key="${key}:" '
    $1 == key { print $2; exit }
  '
}

deployment_secret_ref() {
  local env_name=$1
  awk -v env_name="$env_name" '
    /^---$/ {
      kind = ""
      deployment = ""
      in_metadata = 0
      want_secret_name = 0
    }
    /^kind: Deployment$/ {
      kind = "Deployment"
      next
    }
    kind == "Deployment" && /^metadata:$/ {
      in_metadata = 1
      next
    }
    kind == "Deployment" && in_metadata && /^  name:/ {
      deployment = $2
      in_metadata = 0
      next
    }
    kind == "Deployment" && $1 == "-" && $2 == "name:" && $3 == env_name {
      want_secret_name = 1
      next
    }
    kind == "Deployment" && want_secret_name && $1 == "name:" {
      gsub(/"/, "", $2)
      print deployment "|" $2
      exit
    }
  '
}

env_occurrence_count() {
  local env_name=$1
  awk -v env_name="$env_name" '
    $1 == "-" && $2 == "name:" && $3 == env_name { count++ }
    END { print count + 0 }
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

umbrella_chart="$scratch_root/lifecycle"
mkdir -p "$umbrella_chart"
cp "$repo_root/charts/lifecycle/values.yaml" "$umbrella_chart/values.yaml"
cp -R "$repo_root/charts/lifecycle/templates" "$umbrella_chart/templates"

cat >"$umbrella_chart/Chart.yaml" <<'EOF'
apiVersion: v2
name: lifecycle
description: Minimal dependency-free chart for credential isolation regression tests
type: application
version: 0.0.0-test
appVersion: 0.0.0-test
EOF

cat >"$umbrella_chart/templates/test-credential-secret-names.yaml" <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: test-credential-secret-names
data:
  management: {{ include "..helper.apiKeycloakManagementSecretName" . | quote }}
  principalSync: {{ include "..helper.apiPrincipalSyncSecretName" . | quote }}
EOF

render_umbrella() {
  local release_name=$1
  shift
  helm template "$release_name" "$umbrella_chart" "$@"
}

for release_length in 48 49 53; do
  release_name=$(repeat_a "$release_length")
  rendered=$(render_umbrella "$release_name")

  management_name=$(trim_yaml_scalar "$(
    printf '%s\n' "$rendered" | configmap_data_value management
  )")
  principal_sync_name=$(trim_yaml_scalar "$(
    printf '%s\n' "$rendered" | configmap_data_value principalSync
  )")
  assert_distinct_suffixes \
    "umbrella release length ${release_length}" \
    "$management_name" \
    "$principal_sync_name"

  management_ref=$(trim_yaml_scalar "$(
    printf '%s\n' "$rendered" |
      deployment_secret_ref KEYCLOAK_MANAGEMENT_CLIENT_SECRET
  )")
  principal_sync_ref=$(trim_yaml_scalar "$(
    printf '%s\n' "$rendered" |
      deployment_secret_ref KEYCLOAK_PRINCIPAL_SYNC_CLIENT_SECRET
  )")
  management_ref_count=$(
    printf '%s\n' "$rendered" |
      env_occurrence_count KEYCLOAK_MANAGEMENT_CLIENT_SECRET
  )
  principal_sync_ref_count=$(
    printf '%s\n' "$rendered" |
      env_occurrence_count KEYCLOAK_PRINCIPAL_SYNC_CLIENT_SECRET
  )

  [[ "$management_ref_count" == "1" ]] ||
    fail "umbrella release length ${release_length}: management credential appeared in ${management_ref_count} Deployments"
  [[ "$principal_sync_ref_count" == "1" ]] ||
    fail "umbrella release length ${release_length}: principal-sync credential appeared in ${principal_sync_ref_count} Deployments"
  [[ "$management_ref" == *-lifecycle-web"|${management_name}" ]] ||
    fail "umbrella release length ${release_length}: management credential was not isolated to web (${management_ref})"
  [[ "$principal_sync_ref" == *-lifecycle-worker"|${principal_sync_name}" ]] ||
    fail "umbrella release length ${release_length}: principal-sync credential was not isolated to worker (${principal_sync_ref})"
done

if render_umbrella collision-check \
  --set-string keycloak.clients.lifecycleApiKeycloakManagement.clientSecret.secretKeyRef.name=shared-api-credential \
  --set-string keycloak.clients.lifecycleApiPrincipalSync.clientSecret.secretKeyRef.name=shared-api-credential \
  >/dev/null 2>&1; then
  fail "umbrella chart accepted one Secret identity for both API credentials"
fi

render_umbrella shared-secret-distinct-keys \
  --set-string keycloak.clients.lifecycleApiKeycloakManagement.clientSecret.secretKeyRef.name=shared-api-credential \
  --set-string keycloak.clients.lifecycleApiKeycloakManagement.clientSecret.secretKeyRef.key=managementSecret \
  --set-string keycloak.clients.lifecycleApiPrincipalSync.clientSecret.secretKeyRef.name=shared-api-credential \
  --set-string keycloak.clients.lifecycleApiPrincipalSync.clientSecret.secretKeyRef.key=principalSyncSecret \
  >/dev/null

printf 'Credential Secret isolation render tests passed.\n'
