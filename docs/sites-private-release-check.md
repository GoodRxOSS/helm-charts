# Private Sites chart release checks

The implementation candidate is `lifecycle` chart **0.9.13**, bundling `lifecycle-ui` chart **0.3.6**. These versions are source candidates, not a claim that charts or images have been published. Both chart `appVersion` fields remain 0.2.1 until compatible application image releases are selected; those historical defaults must not be assumed to contain Sites access control.

## Packaging and image ordering

1. Build and validate the matching core and UI image candidates. Select their actual released tags for `global.image.tag` and `ui.image.tag`; check any `components.<name>.image.tag` overrides, which take precedence for core workloads. Do not enable private Sites while an old web, gateway, worker, or UI image still participates in Sites operations.
2. From a checkout containing both sibling charts, run `helm dependency update charts/lifecycle`. The exact `lifecycle-ui` version 0.3.6 resolves through `file://../lifecycle-ui`; this packages the local matching UI templates into the umbrella archive. `Chart.lock` and downloaded `charts/` contents are ignored according to repository convention. Regenerate the lock/dependency packages and retain their digest in release evidence.
3. Lint and render the full umbrella and standalone UI with Helm 3.14.0, matching CI. Package both charts only after the matching-image and runtime checks pass. Repository release automation resolves all dependencies before publishing charts, so a same-commit HTTP reference to an unpublished UI version would fail. The local sibling dependency removes that ordering race; consumers of the published umbrella archive need no sibling checkout.
4. Complete enabled acceptance in an isolated deployment, then use the coordinated production barrier below. Do not start any new core image against production before that barrier. Startup runs `pnpm db:migrate`, even when the private readiness flag is disabled. A normal image-only rolling upgrade leaves incompatible legacy writers running during migration.

No publication, deployment, or image tag fabrication is performed by editing this source candidate.

## Configuration paths

Core settings live at top-level `sitesPrivate`. The UI uses its existing NextAuth
session, `NEXTAUTH_URL` and `NEXT_PUBLIC_API_URL`, populated by `ui.config.appUrl`
and `ui.config.apiUrl`. Core derives `SITES_UI_ORIGIN` from the bundled UI's app URL,
falling back to `https://<global.uiSubDomain>.<global.domain>`. Set
`sitesPrivate.uiOrigin` explicitly for a standalone UI. No Sites bridge secret,
separate UI flag, UI OAuth-client binding or directory client is required.

```yaml
global:
  image:
    tag: YOUR_VALIDATED_CORE_IMAGE_TAG
components:
  gateway:
    enabled: true
sitesPrivate:
  enabled: false
ui:
  image:
    tag: YOUR_VALIDATED_UI_IMAGE_TAG
  config:
    appUrl: https://ui.example.com
    apiUrl: https://api.example.com
keycloak:
  clients:
    lifecycleApiPrincipalSync:
      enabled: true
```

The example keeps private access disabled for production preparation. Enable it
only in the isolated acceptance deployment or at the production enablement step.
The canonical UI and API URLs must be reachable by the UI server as well as the
browser; validate the existing API route and reverse-proxy configuration.
For a standalone UI chart, use its top-level `config.appUrl` and `config.apiUrl`,
and set the matching `sitesPrivate.uiOrigin` on core.

Core must have authentication enabled and a matching verified issuer. Human Sites
management and new grants reuse the existing read-only
`keycloak.clients.lifecycleApiPrincipalSync` client and Secret contract. The chart
injects `KEYCLOAK_PRINCIPAL_SYNC_CLIENT_ID` and `KEYCLOAK_PRINCIPAL_SYNC_CLIENT_SECRET`
into worker, web and gateway whenever that bundled identity contract is enabled,
including when private access is off. Optional external Secret name/key overrides
retain their existing behavior. The privileged management client stays web-only
and must never substitute for the read-only client. For external Keycloak
(`keycloak.enabled=false`), supply the same principal-status environment variables
through the existing workload environment/Secret configuration.

The bundled client's existing `view-users` / `query-users` roles are unchanged.
Verify user status, sessions, composite-role/group reads and incoming-token
introspection against the selected Keycloak version, including long-lived
personal keys, CLI tokens and dynamically registered MCP offline tokens. Probe
these permissions with the existing read-only client before release. Realm import
is one-shot; an existing realm may need its existing client/Secret reconciled
externally. No additional Sites client is provisioned by this chart.

Private asset reads use a Site-only grant plus current Site state, without
per-asset identity-provider calls or retaining the original OAuth bearer. Grants
expire after at most 300 seconds and no later than the authorizing JWT. The chart's
Keycloak realm specifies a 300-second token default; verify actual issued tokens
and any existing-realm overrides. An authenticated, authorized user can renew with
a valid JWT, including one refreshed through the ordinary UI session. A Site
cookie alone cannot extend authorization beyond its JWT deadline.

Local logout clears the UI session and stops its ordinary refresh path. It does
not immediately revoke issued JWTs/grants, other logins or Keycloak SSO. Account
or token revocation may take until the issued viewing grant's deadline to stop
existing viewing access; newly issued grants and management still check identity.
Site deletion, expiration, ownership/revision and public-to-private host retirement
are checked before bytes on each request. Loaded bytes cannot be recalled.

Use an HTTPS content domain with a different registrable domain from the UI and host-only content cookies. Storage must remain private, with no public bucket/object URL bypass. Supply the Sites storage/domain configuration through the application's supported admin configuration. Route all content through authorization-capable gateways.

When disabling private creation or performing a forward rollback, retain the
ACL-capable core/gateway images, schema, trusted UI origin and existing principal-
status credential configuration. Disable the core flag; private reads must fail
closed while human public-Site management retains identity checks. Disabled
private readiness stops all human uploads, including explicitly public uploads;
service-key public uploads remain available when Sites is enabled.

## Coordinated production barrier

Schedule a maintenance window. This procedure temporarily stops all core API, gateway, and worker workloads; review effects on queued jobs and other product tasks. Keep PostgreSQL, Redis, object storage and Keycloak available. Suspend GitOps, autoscalers and other reconcilers that could restore old replicas. Inventory external/all-mode writers, gateways and direct storage paths as well as this Helm release.

1. Test the exact image/chart set in an isolated deployment with **private access enabled**. Verify owner access and unrelated/anonymous denial for HTML and assets; current identity checks for new grants/management; publication, old-host retirement, expiration and deletion. Test JWT-bounded grants, authenticated sliding renewal, local logout/refresh races and account-switch isolation. Confirm issued grants may survive logout/account revocation until their deadline. Complete the read-only principal-status capability probe before scheduling production migration.
2. Back up the production database, object storage, configuration and Secrets as one recovery checkpoint. Verify the existing read-only principal-status account and canonical UI/API routing before replacing existing workloads.
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
   ```

   ```sh
   helm upgrade "$RELEASE" "$CURRENT_CHART" -n "$NAMESPACE" \
     -f CURRENT_VALUES.yaml -f MAINTENANCE_VALUES.yaml --wait
   kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE"
   ```

   Verify all inventoried old core pods have terminated and no external writer or gateway remains. Do not use `replicaCount: 0`: this chart's defaulting renders it as one replica. Do not use automatic Helm rollback across the migration.
5. Render the candidate with reviewed production values, the core flag disabled, only `web` enabled, and `web.deployment.replicaCount: 1`. Keep `worker` and `gateway` disabled in a separate `FIRST_WEB_VALUES.yaml`:

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
   ```

   Start that single new web instance:

   ```sh
   helm upgrade "$RELEASE" "$CANDIDATE_CHART" -n "$NAMESPACE" \
     -f CANDIDATE_VALUES.yaml -f FIRST_WEB_VALUES.yaml --wait
   ```

   Verify startup completed the access-control migration successfully before starting any other core instance. Verify migrated rows remain public and unassigned through the reviewed migration checks. The first instance runs the migration; later compatible startups find it already applied. Abort with traffic fenced if migration or readiness fails.
6. Apply the complete candidate values with all intended components restored and the core flag still disabled. Verify every API, worker, gateway and UI runs its selected compatible image. Verify principal-status reads and public-site management, private-content denial, canonical UI/API routing, DNS/TLS and absence of storage bypass. Replace incompatible CLI clients and identity-unbound personal keys. Disabled-state checks do not exercise private access.
7. Enable `sitesPrivate.enabled` while the traffic fence remains. Repeat the enabled access tests through a restricted operator test path. If they pass, reopen traffic and resume reconcilers with the compatible desired state. If they fail, disable the core flag and verify private-content denial before deciding whether to reopen public traffic.

Forward recovery retains the ACL-capable core/gateway images, schema, trusted UI origin and read-only principal-status credentials. Disabling private access does not make private data public and does not permit legacy binaries to return. Restore the complete pre-upgrade checkpoint only in isolation under the tested recovery procedure.

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

Validate only core web/gateway receive the private flag, trusted UI origin and proxy
settings. Worker/web/gateway receive the shared read-only principal-status Secret;
management remains web-only, and the UI receives neither credential. Repeat with
the core flag disabled and verify principal-status references remain. Validate
custom client/Secret key overrides, disabled/missing client configuration, gateway
disablement and existing bundled/standalone UI canonical URLs. Run the focused
render regressions:

```sh
bash scripts/test-sites-private-config.sh
bash scripts/test-keycloak-credential-isolation.sh
```

These checks complement runtime owner/nonowner/anonymous access, bounded/sliding
renewal, logout races, URL retirement, storage isolation and migration acceptance.
Helm renders cannot establish those runtime properties.

## Existing optional MinIO limitation

With the repository's current `minio.enabled=true` image overrides, pinned upstream MinIO chart 17.0.21 rejects the `bitnamilegacy` image names during its container-image validation. The same failure occurs on unmodified repository HEAD; it is not introduced by Sites ACL changes. The full default chart renders with MinIO disabled, as configured by default. Resolve the bundled storage image/chart compatibility before enabling that dependency. This candidate does not suppress the upstream validation or claim production MinIO deployment acceptance.
