# Charts

In-tree Helm charts deployed by Flux HelmReleases under [`../flux`](../flux).

Most app charts use explicit Kubernetes manifests. Helm is used for light
substitution, mostly `.Chart.Name` and shared non-secret values passed by Flux.
Avoid shared Deployment/Service/PVC helpers; app-specific behavior should stay
visible in the app chart.

## Layout

```text
charts/
├── aly-codes/              # Static site (aly.codes)
├── audiobookshelf/         # Audiobook library with rclone-mounted media
├── tranquil-pds/           # Reference atproto Personal Data Server
├── cert-manager-issuers/   # Let's Encrypt ClusterIssuer + wildcard Certificates
├── cluster-tls/            # Cloudflare Origin TLS Secrets per domain
├── external-routes/        # Ingress + Service + EndpointSlice for off-cluster targets
├── forgejo/                # Git hosting (git.aly.codes)
├── forward-auth/           # Per-app traefik-forward-auth frontends
├── immich/                 # Photo library + ML + app-specific Postgres
├── longhorn-creds/         # B2 backup Secret + recurring backup job + UI ingress
├── paperless/              # Document management with rclone media mount
├── pg-shared/              # CloudNativePG cluster using local-path replicas
└── ...
```

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

## Data-Driven Exceptions

Some charts intentionally render repeated resources from values:

- **`forward-auth`** renders one auth Deployment/Service/Ingress/Middleware set
  per `.Values.apps` entry.
- **`external-routes`** renders off-cluster Service, EndpointSlice, and Ingress
  resources from `.Values.routes`.
- **`pg-shared`** renders CNPG roles/databases and backup resources from chart
  values.
- **`cluster-tls`** and **`cert-manager-issuers`** render repeated TLS or
  certificate resources from values.

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
