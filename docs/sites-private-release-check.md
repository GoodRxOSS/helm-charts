# Private Sites chart release checks

The implementation candidate is `lifecycle` chart **0.9.13**, bundling `lifecycle-ui` chart **0.3.6**. These versions are source candidates, not a claim that charts or images have been published. Both chart `appVersion` fields remain 0.2.1 until compatible application image releases are selected; those historical defaults must not be assumed to contain Sites access control.

## Packaging and image ordering

1. Build and validate the matching core and UI image candidates. Select their actual released tags for `global.image.tag` and `ui.image.tag`; check any `components.<name>.image.tag` overrides, which take precedence for core workloads. Do not enable private Sites while an old web, gateway, worker, or UI image still participates in Sites operations.
2. From a checkout containing both sibling charts, run `helm dependency update charts/lifecycle`. The exact `lifecycle-ui` version 0.3.6 resolves through `file://../lifecycle-ui`; this packages the local matching UI templates into the umbrella archive. `Chart.lock` and downloaded `charts/` contents are ignored according to repository convention. Regenerate the lock/dependency packages and retain their digest in release evidence.
3. Lint and render the full umbrella and standalone UI with Helm 3.14.0, matching CI. Package both charts only after the matching-image and runtime checks pass. Repository release automation resolves all dependencies before publishing charts, so a same-commit HTTP reference to an unpublished UI version would fail. The local sibling dependency removes that ordering race; consumers of the published umbrella archive need no sibling checkout.
4. Complete enabled acceptance in an isolated deployment, then use the coordinated production barrier below. Do not start any new core image against production before that barrier. Startup runs `pnpm db:migrate`, even when both private flags are disabled. A normal image-only rolling upgrade leaves incompatible legacy writers running during migration.

No publication, deployment, or image tag fabrication is performed by editing this source candidate.

## Configuration paths

For the umbrella chart, core settings live at top-level `sitesPrivate`; bundled UI settings live at `ui.sitesPrivate`. Setting only core values does not automatically configure UI. The same bridge Secret value must be available to both workloads in their respective namespaces. This is a dedicated random secret of at least 32 bytes, separate from NextAuth and preview credentials.

```yaml
global:
  image:
    tag: YOUR_VALIDATED_CORE_IMAGE_TAG
components:
  gateway:
    enabled: true
sitesPrivate:
  enabled: false
  uiOAuthClientId: YOUR_UI_KEYCLOAK_CLIENT_ID
  uiOrigin: https://ui.example.com
  bridgeSecret:
    name: sites-browser-bridge
    key: sitesBrowserBridgeSecret
  directory:
    clientId: lifecycle-sites-directory
    secretName: sites-directory
    secretKey: clientSecret
ui:
  image:
    tag: YOUR_VALIDATED_UI_IMAGE_TAG
  sitesPrivate:
    enabled: false
    uiOrigin: https://ui.example.com
    apiInternalUrl: http://YOUR_CORE_WEB_SERVICE
    bridgeSecret:
      name: sites-browser-bridge
      key: sitesBrowserBridgeSecret
```

The example keeps both flags disabled for production preparation. Enable both only in the isolated acceptance deployment or at the production enablement step. `uiOAuthClientId` must equal the UI's `NEXT_PUBLIC_KEYCLOAK_CLIENT_ID`.

The web Service uses `components.web.service.port`, which defaults to 80. Its default name is `<release>-lifecycle-web` (or `<release>-web` when the release name contains `lifecycle`). `fullnameOverride`, `nameOverride`, or `components.web.fullnameOverride` can change it. Read the rendered Service name and port; use that Service DNS name, including its namespace for a separately installed UI. Do not use the pod/container port as the Service port.

For a standalone UI chart, remove the outer `ui:` level. Core must have authentication enabled, a matching verified issuer, and a separately provisioned read-only directory client. Directory credentials are required for all human Sites management, including public Sites with private creation disabled. The same confidential directory client must authenticate token introspection at `<issuer>/protocol/openid-connect/token/introspect`. Verify active, revoked and disabled-user credentials, including CLI and dynamically registered MCP offline tokens. Keep only `view-users`; no client search or client UUID mapping is required. The chart references existing Secrets; it does not reconcile a directory client into an existing Keycloak realm. Keep management, worker principal-sync, and Sites directory credentials separate.

Use an HTTPS content domain with a different registrable domain from the UI and host-only content cookies. Storage must remain private, with no public bucket/object URL bypass. Supply the Sites storage/domain configuration through the application's supported admin configuration. Route all content through authorization-capable gateways.

When disabling private creation or performing a forward rollback, preserve the configured core/UI bridge Secret, UI origin, internal API URL, and directory values for existing login revocation and human public-site access. Disable the flags; do not remove their credential configuration prematurely. Disabled private readiness stops all human uploads, including explicitly public uploads; service-key public uploads remain available when Sites is enabled.

## Coordinated production barrier

Schedule a maintenance window. This procedure temporarily stops all core API, gateway, and worker workloads; review effects on queued jobs and other product tasks. Keep PostgreSQL, Redis, object storage and Keycloak available. Suspend GitOps, autoscalers and other reconcilers that could restore old replicas. Inventory external/all-mode writers, gateways and direct storage paths as well as this Helm release.

1. Test the exact image/chart set in an isolated deployment with **both flags enabled**. Verify owner access, unrelated-user denial, disabled-user and terminated-session denial, publication, privatization with old-host retirement, expiration, deletion and logout. Complete the directory capability probe before scheduling production migration.
2. Back up the production database, object storage, configuration and Secrets as one recovery checkpoint. Provision and verify the directory account and bridge configuration before replacing existing workloads. Resolve the directory prerequisite in [the configuration guide](https://uselifecycle.com/docs/operations/configuration#sites-directory-release-prerequisite).
3. Fence Sites requests at every external and internal entry point, including service-key/automation uploads and content hosts. Drain requests. Stop external legacy writers and gateways. Keep this fence until the compatible deployment passes its checks.
4. Apply a reviewed maintenance values file that disables every core component. Use the **currently installed chart and image values**, not the new image. The standard component names are `web`, `worker`, and `gateway`; include any custom components. For example:

   ```yaml
   components:
     web:
       enabled: false
     worker:
       enabled: false
     gateway:
       enabled: false
   sitesPrivate:
     enabled: false
   ui:
     sitesPrivate:
       enabled: false
   ```

   ```sh
   helm upgrade "$RELEASE" "$CURRENT_CHART" -n "$NAMESPACE" \
     -f CURRENT_VALUES.yaml -f MAINTENANCE_VALUES.yaml --wait
   kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE"
   ```

   Verify all inventoried old core pods have terminated and no external writer or gateway remains. Do not use `replicaCount: 0`: this chart's defaulting renders it as one replica. Do not use automatic Helm rollback across the migration.
5. Render the candidate with reviewed production values, both flags disabled, only `web` enabled, and `web.deployment.replicaCount: 1`. Keep `worker` and `gateway` disabled in a separate `FIRST_WEB_VALUES.yaml`:

   ```yaml
   components:
     web:
       enabled: true
       deployment:
         replicaCount: 1
     worker:
       enabled: false
     gateway:
       enabled: false
   sitesPrivate:
     enabled: false
   ui:
     sitesPrivate:
       enabled: false
   ```

   Start that single new web instance:

   ```sh
   helm upgrade "$RELEASE" "$CANDIDATE_CHART" -n "$NAMESPACE" \
     -f CANDIDATE_VALUES.yaml -f FIRST_WEB_VALUES.yaml --wait
   ```

   Verify startup completed the access-control migration successfully before starting any other core instance. Verify migrated rows remain public and unassigned through the reviewed migration checks. The first instance runs the migration; later compatible startups find it already applied. Abort with traffic fenced if migration or readiness fails.
6. Apply the complete candidate values with all intended components restored and both flags still disabled. Verify every API, worker, gateway and UI runs its selected compatible image. Verify directory reads and public-site management, private-content denial, internal bridge connectivity, DNS/TLS and absence of storage bypass. Replace incompatible CLI clients and identity-unbound personal keys. Disabled-state checks do not exercise private access.
7. Enable `sitesPrivate.enabled` and `ui.sitesPrivate.enabled` together while the traffic fence remains. Repeat the enabled access tests through a restricted operator test path. If they pass, reopen traffic and resume reconcilers with the compatible desired state. If they fail, disable both flags and verify private-content denial before deciding whether to reopen public traffic.

Forward recovery retains the ACL-capable core/gateway images, schema, UI OAuth client ID, origin and directory/bridge credentials. Disabling flags does not make private data public and does not permit legacy binaries to return. Restore the complete pre-upgrade checkpoint only in isolation under the tested recovery procedure.

## Full-chart validation

```sh
helm dependency update charts/lifecycle
helm lint charts/lifecycle --with-subcharts -f PRIVATE_VALUES.yaml
helm lint charts/lifecycle-ui -f STANDALONE_UI_VALUES.yaml
helm template candidate charts/lifecycle -f PRIVATE_VALUES.yaml \
  --api-versions k8s.keycloak.org/v2alpha1
helm template candidate charts/lifecycle-ui -f STANDALONE_UI_VALUES.yaml
```

The Keycloak capability argument describes a required installed operator CRD for offline rendering. Rendering without it correctly fails when bundled Keycloak is enabled. It does not install or validate the CRD on a real cluster.

Validate core web/gateway and UI receive their private flag and bridge reference; only web/gateway receive the separate directory reference. Repeat with both flags disabled while retaining configuration and verify credential references remain. Validate missing enabled-state credentials and gateway disablement fail rendering. These checks complement runtime browser logout, owner/nonowner, URL retirement, object-storage isolation, and migration acceptance.

## Existing optional MinIO limitation

With the repository's current `minio.enabled=true` image overrides, pinned upstream MinIO chart 17.0.21 rejects the `bitnamilegacy` image names during its container-image validation. The same failure occurs on unmodified repository HEAD; it is not introduced by Sites ACL changes. The full default chart renders with MinIO disabled, as configured by default. Resolve the bundled storage image/chart compatibility before enabling that dependency. This candidate does not suppress the upstream validation or claim production MinIO deployment acceptance.
