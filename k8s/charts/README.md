# Charts

In-tree Helm charts deployed by Flux HelmReleases under [`../flux`](../flux).
Small hand-authored workloads live as raw Kustomize manifests in their Flux
layer instead of as charts.

Helm is reserved for upstream packages, reusable releases, and charts that
need data-driven rendering. Avoid shared Deployment/Service/PVC helpers;
app-specific behavior should stay visible in direct manifests.

## Layout

```text
charts/
├── cert-manager-issuers/   # Let's Encrypt ClusterIssuer + wildcard Certificates
├── external-routes/        # Ingress + Service + EndpointSlice for off-cluster targets
├── forward-auth/           # Per-app traefik-forward-auth frontends
├── longhorn-creds/         # B2 backup Secret + recurring backup job + UI ingress
├── paperless/              # Document management with rclone media mount
├── pg-shared/              # CloudNativePG cluster using local-path replicas
└── ...
```

Undeployed charts live in [`../drafts`](../drafts), outside the Flux chart
inventory. See its README before promoting a draft to production.

## Workload Styles

Use raw Kustomize manifests for fixed, hand-authored workloads. Their files
live beside the Flux layer that applies them, for example
`../flux/apps/watsup/` or `../flux/platform/tika/`. Each directory has a
small `kustomization.yaml` that sets its namespace and lists its resources.

Use Helm only when release reuse or structured rendering is meaningful. The
remaining local Helm charts are data-driven or stateful; they are not generic
wrappers around otherwise static YAML.

## Chart Style

Prefer direct manifests:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: { { .Chart.Name } }
  labels:
    app: { { .Chart.Name } }
spec:
  selector:
    matchLabels:
      app: { { .Chart.Name } }
  template:
    metadata:
      labels:
        app: { { .Chart.Name } }
    spec:
      automountServiceAccountToken: false
      enableServiceLinks: false
      containers:
        - name: { { .Chart.Name } }
          image: example/app:1.0.0@sha256:...
```

Use this pod-spec order when practical:

```yaml
automountServiceAccountToken: false
enableServiceLinks: false
terminationGracePeriodSeconds: 30
securityContext:
tolerations:
hostNetwork:
dnsPolicy:
nodeSelector:
imagePullSecrets:
topologySpreadConstraints:
initContainers:
containers:
volumes:
```

Only include fields that the app actually needs. Do not add shared helpers just
to make every chart identical.

## Templating Rules

Keep these:

- `.Chart.Name` for names, labels, selectors, and PVC names.
- Small `range` loops for charts that are naturally data-driven.

Avoid these:

- Common Deployment/Service/PVC helper templates.
- Values that model arbitrary pod specs, containers, sidecars, volumes, or env.
- Large `_helpers.tpl` files for simple app charts.

## Chart Tiers

Charts fall into three readability tiers:

- **Configurable application charts** such as Paperless, Nextcloud, and Immich
  render meaningful values that affect the workload.
- **Data-driven charts** render repeated resources from structured values:
  `forward-auth`, `external-routes`, `pg-shared`, and
  `cert-manager-issuers`.

Do not move Helm charts into namespace-named directories. The HelmRelease is
the deployment boundary, and a chart can be reused by multiple releases. Fixed
hand-authored workloads belong in their Flux layer as raw manifests instead.

## Data-Driven Exceptions

Some charts intentionally render repeated resources from values:

- **`forward-auth`** renders one auth Deployment/Service/Ingress/Middleware set
  per `.Values.apps` entry.
- **`external-routes`** renders off-cluster Service, EndpointSlice, and Ingress
  resources from `.Values.routes`.
- **`pg-shared`** renders CNPG roles/databases and backup resources from chart
  values.
- **`cert-manager-issuers`** renders repeated certificate resources from values.

Those are data charts rather than app workload charts, so a little looping is
acceptable there.

## Intel GPU Scheduling

Intel GPU nodes are labeled from the NixOS `intel-gpu` module:

```yaml
nodeSelector:
  cute.haus/intel-gpu: "true"
```

For pods that need actual GPU access, also request and limit the Intel device
plugin resource:

```yaml
resources:
  requests:
    gpu.intel.com/i915: "1"
  limits:
    gpu.intel.com/i915: "1"
```

Do not use `gpu.intel.com/i915` as a `nodeSelector`; the Intel device plugin
publishes that as node capacity/allocatable, not as a stable node label.

## Secret Flow

```text
k8s/flux/secrets/foo.sops.yaml  SOPS-encrypted Kubernetes Secret
        |
        v
Flux kustomize-controller        decrypts with flux-system/sops-age
        |
        v
Kubernetes Secret                first-class object in target namespace
        |
        v
Deployment envFrom/secretRef     app consumes the Secret
```

Flux decrypts only `k8s/flux/secrets/*.sops.yaml`; host/Terraform secrets under
`secrets/*.yaml` remain user/host-key scoped.

## Adding An App

1. Create `charts/<name>/Chart.yaml`.
2. Add explicit templates for only the resources the app needs, usually
   `deployment.yaml`, `service.yaml`, `ingress.yaml`, optional `pvc.yaml`, and
   optional `secret.yaml`.
3. Put app-specific behavior directly in those manifests.
4. If the app needs secrets, create first-class SOPS Secret manifests under
   `../flux/secrets/` and reference those Secret names from the chart.
5. Add a HelmRelease under `../flux/apps/`.
6. Render before applying:

```bash
helm template <name> charts/<name>
flux reconcile kustomization apps -n flux-system
```
