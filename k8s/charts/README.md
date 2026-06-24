# 🪐 Charts

In-tree Helm charts deployed by [`../helmfile.yaml`](../helmfile.yaml).

App charts share a library chart (`common/`); their `templates/*.yaml` files
are one-line includes of `common.deployment` / `common.service` / etc., and
all per-app config lives in `values.yaml`.

---

## 📂 Layout

```plaintext
charts/
├── aly-codes/              # Static site (aly.codes)
├── bluesky-pds/            # Reference atproto Personal Data Server
├── cert-manager-issuers/   # Let's Encrypt ClusterIssuer + wildcard Certificates (Cloudflare DNS-01)
├── cluster-tls/            # Cloudflare Origin TLS Secrets per domain
├── common/                 # Library chart with shared partials
├── external-routes/        # Ingress + Service + EndpointSlice for off-cluster targets
├── forgejo/                # Git hosting (git.aly.codes)
├── longhorn-creds/         # B2 backup-target Secret + recurring backup job + UI ingress
├── morsels/                # atproto pastebin (morsels.blue)
├── pg-shared/              # CloudNativePG cluster using local-path replicas
├── tranquil-pds/           # TRanquil atproto Personal Data Server
├── uptime-kuma/            # Uptime monitoring + status pages
├── vaultwarden/            # Bitwarden-compatible vault
└── watsup/                 # Homelab dashboard (cute.haus)
```

---

## 🔐 Secret flow

```
secrets/foo.yaml         (SOPS-encrypted, multi-recipient age)
        │
        ▼ vals reads ref+sops:// at render time
values/foo.yaml          (plain yaml of ref+sops://... refs)
        │
        ▼ helmfile passes it as values: to the release
chart's values.yaml      (.Values.secret.* now plaintext during render)
        │
        ▼
common.secret partial    → kind: Secret with stringData
        │
        ▼
deployment.envFrom       → env vars in the container
```

`vals` resolves `ref+sops://` URLs at render time using whichever age key
is at `~/.config/sops/age/keys.txt` (run `just sops-bootstrap` once on a
new machine to derive that from the SSH host key).

---

## 🆕 Add a new app

```bash
just new-app <name>
```

Then:

1. Edit `charts/<name>/values.yaml` — image, ports, env, ingress routes,
   persistence.
2. Add a release block to `helmfile.yaml`:
   ```yaml
   - name: <name>
     namespace: default
     chart: ./charts/<name>
   ```
3. If the app needs secrets:
   - `just sops-edit <name>.yaml` — write the encrypted file
   - Create `values/<name>.yaml` with `ref+sops://../secrets/<name>.yaml#/...`
     refs for each key (path is relative to `k8s/`, where helmfile runs)
   - Add `values: [values/<name>.yaml]` to the helmfile release
4. `helmfile -l name=<name> apply`

---

## 🧱 Library chart

App templates are thin includes:

```yaml
# charts/<app>/templates/deployment.yaml
{ { - include "common.deployment" . } }
```

The library defines `common.deployment`, `common.service`, `common.ingress`,
`common.pvc`, `common.secret`. See [`common/README.md`](common/README.md) for
each partial's values reference.

---

## 🚫 Charts that don't use `common/`

These have unique enough shape that the library wouldn't help:

- **`cluster-tls`** — renders one `kubernetes.io/tls` Secret per entry in
  `.Values.secret`, sourced from `secrets/cluster-tls.yaml`.
- **`pg-shared`** — a CNPG `Cluster` using `local-path` volumes for Postgres
  data. CNPG provides HA with streaming replication across instances; B2
  backups and WAL archiving cover recovery. A `longhorn-pg` StorageClass is
  rendered for experiments or a future migration, but the live cluster does not
  use it. Apps that need a database get a role + database created manually in
  this cluster; there's no per-app provisioning yet.
- **`external-routes`** — for each entry in `.Values.routes`, renders a
  `Service` + `EndpointSlice` + `Ingress` pointing at an external IP
  (typically a Tailscale IP for a service running on jubilife or eterna).
  Supports both traefik and tailscale ingress classes.
- **`cert-manager-issuers`** — one `ClusterIssuer` (Let's Encrypt + Cloudflare
  DNS-01) plus one wildcard `Certificate` per entry in `.Values.wildcards`.
  Each cert lands as a Secret apps reference via `tlsSecret` in ingress routes.
- **`longhorn-creds`** — the B2 credentials Secret that Longhorn references via
  `defaultBackupStore.backupTargetCredentialSecret`, plus a daily `RecurringJob`
  for the `default` volume group and an Ingress exposing the Longhorn UI on the
  tailnet. Must apply before `longhorn` (the `needs:` chain enforces this).
