# Kubernetes operations

Flux is the deployment controller. Git is the desired state: make and review a
change here, merge it, then let Flux reconcile it. Use `just k8s-status` first
when the cluster looks unhealthy; it prints only actionable failures.

## Normal changes and incidents

```bash
just check
git push
flux reconcile kustomization apps -n flux-system --with-source
just k8s-status
```

Preview a local chart with `just k8s diff <release> <namespace>`. Use
`just k8s suspend`, `resume`, and `reconcile` for a HelmRelease; do not use
`helm upgrade` as a deployment path.

For an emergency live recovery: suspend the affected HelmRelease, make the
minimum live recovery change, commit the desired fix, then resume and reconcile
the release. Flux must regain Git authority before the incident is closed.

Useful incident commands:

```bash
flux get kustomizations -A
flux get helmreleases -A
kubectl get pods,pvc,certificate -A
flux suspend helmrelease <release> -n flux-system
flux reconcile helmrelease <release> -n flux-system --with-source
kubectl rollout undo deployment/<name> -n <namespace>
```

`kubectl rollout undo` is temporary recovery only: capture the resulting desired
configuration in Git, then reconcile Flux. Helm rollback is likewise an
emergency measure (`helm history` then `helm rollback`) while the release is
suspended.

## Platform and identity namespace migration

Apply the Tika, Gotenberg, and forward-auth namespace move as a controlled
maintenance operation. The new HelmRelease targets must not overlap the old
release state.

```bash
flux suspend helmrelease tika -n flux-system
flux suspend helmrelease gotenberg -n flux-system
flux suspend helmrelease forward-auth -n flux-system

# Merge the desired state, then create namespaces and the identity Secret.
flux reconcile kustomization secrets -n flux-system --with-source

# Once the identity Secret exists, remove the old release records only.
helm uninstall tika -n default
helm uninstall gotenberg -n default
helm uninstall forward-auth -n default

flux resume helmrelease tika -n flux-system
flux resume helmrelease gotenberg -n flux-system
flux resume helmrelease forward-auth -n flux-system
flux reconcile kustomization platform -n flux-system --with-source
flux reconcile kustomization apps -n flux-system --with-source
```

Then verify `paperless` starts with `tika.platform.svc` and
`gotenberg.platform.svc`, and open Navidrome through
`identity-forward-auth-navidrome`. This intentionally causes a short outage for
the three moved services.

## Service inventory

This table is maintained with the Flux workload declarations. `local-path` means
node-local or host-mounted data and must be recovered on its owning node.

| Release          | Delivery     | Namespace   | URL                          | Dependencies                       | Persistence                                    | Backup / restore owner         | Data-loss expectation                   |
| ---------------- | ------------ | ----------- | ---------------------------- | ---------------------------------- | ---------------------------------------------- | ------------------------------ | --------------------------------------- |
| aly-codes        | Kustomize    | websites    | https://aly.codes            | —                                  | none                                           | Git/site build                 | rebuildable                             |
| collabora        | Kustomize    | default     | https://collabora.cute.haus  | nextcloud                          | none                                           | configuration only             | rebuildable                             |
| error-pages      | Kustomize    | default     | internal                     | traefik                            | none                                           | Git                            | rebuildable                             |
| forward-auth     | forward-auth | identity    | internal                     | Pocket ID                          | SOPS secret                                    | SOPS / identity operator       | reconfigure clients                     |
| gotenberg        | Kustomize    | platform    | internal                     | —                                  | none                                           | Git                            | rebuildable                             |
| immich           | immich       | default     | https://immich.cute.haus     | valkey                             | local-path uploads/ML cache, Longhorn database | node owner / Immich export     | photo loss possible without node data   |
| morsels          | morsels      | websites    | https://morsels.blue         | —                                  | Longhorn                                       | Longhorn backup owner          | restore from volume backup              |
| navidrome        | navidrome    | default     | https://navidrome.cute.haus  | forward-auth                       | Longhorn config, host media                    | Longhorn / media host owner    | media is external; config may be lost   |
| nextcloud        | nextcloud    | nextcloud   | https://nextcloud.cute.haus  | pg-shared, valkey-nextcloud        | local-path HTML, CNPG/Garage data              | node owner / CNPG backup owner | file loss possible without node data    |
| ombi             | ombi         | default     | https://ombi.cute.haus       | —                                  | Longhorn                                       | Longhorn backup owner          | restore config/database                 |
| paperless        | paperless    | default     | https://paperless.cute.haus  | pg-shared, valkey, tika, gotenberg | local-path data                                | node owner / CNPG backup owner | documents may be lost without node data |
| pg-shared        | pg-shared    | cnpg-system | internal                     | CNPG                               | Longhorn database volumes, B2 backups          | CNPG backup owner              | point-in-time limited to backups        |
| plex             | NixOS        | jubilife    | https://plex.cute.haus       | media host                         | local-path config and media mounts             | node/media owner               | config or metadata loss possible        |
| pocket-id        | Kustomize    | identity    | https://id.cute.haus         | pg-shared                          | CNPG                                           | CNPG backup owner              | identity records depend on DB backup    |
| seerr            | seerr        | default     | https://seerr.cute.haus      | pg-shared                          | Longhorn config, CNPG                          | Longhorn / CNPG backup owner   | restore app config and DB               |
| slingshot        | NixOS        | jubilife    | https://slingshot.cute.haus  | —                                  | ephemeral cache                                | Git                            | rebuildable                             |
| switchyard       | Kustomize    | websites    | https://switchyard.aly.codes | —                                  | none                                           | Git/site build                 | rebuildable                             |
| tika             | Kustomize    | platform    | internal                     | —                                  | none                                           | Git                            | rebuildable                             |
| tranquil-pds     | Kustomize    | default     | https://pds.cute.haus        | pg-shared, valkey                  | CNPG, B2 repository data                       | CNPG/B2 owner                  | account data loss without backups       |
| uptime-kuma      | uptime-kuma  | default     | https://kuma.cute.haus       | —                                  | Longhorn                                       | Longhorn backup owner          | monitor history/config loss possible    |
| vaultwarden      | vaultwarden  | default     | https://vault.cute.haus      | —                                  | Longhorn                                       | Longhorn backup owner          | vault loss is critical                  |
| valkey           | valkey       | default     | internal                     | —                                  | Longhorn                                       | Longhorn backup owner          | cache/session loss tolerated            |
| valkey-nextcloud | valkey       | nextcloud   | internal                     | —                                  | Longhorn                                       | Longhorn backup owner          | cache/session loss tolerated            |
| watsup           | Kustomize    | websites    | https://cute.haus            | —                                  | ConfigMap                                      | Git                            | rebuildable                             |

## Stateful recovery

- Longhorn: inspect replicas and backups with `kubectl -n longhorn-system get
volumes,longhornbackups`; restore to a new volume/PVC, verify it, then point
  the workload at it. Do not delete the original volume while diagnosing.
- local-path and host-path: identify the PVC's node with `kubectl get pv` and
  recover the data on that node before rescheduling. The storage class does not
  provide replication.
- CNPG: use the `pg-shared` ScheduledBackup/B2 path, restore to a separate
  Cluster, validate databases and roles, then plan the controlled cutover.
  Never overwrite the live cluster as the first recovery action.

## Uptime Kuma checklist (v1)

Kuma is configured in its UI; this checklist is the versioned source of
monitoring intent. After every deployment, configure HTTPS monitors for every
public URL in the inventory, including all `pds.cute.haus`, `aly.social`,
`status.cute.haus`, `status.aly.codes`, and `status.aly.social` routes.

- Confirm each monitor runs externally, follows the intended HTTP success rule,
  and validates TLS expiry/certificate hostname.
- Put public customer-facing endpoints on the correct Kuma status page.
- Open each status page from outside the cluster and confirm its monitor state
  and TLS certificate are visible.
- Record new URLs here before adding their UI monitor; remove UI monitors only
  after removing the URL from this checklist.
