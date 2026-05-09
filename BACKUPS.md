# 💾 Backups

Two layers → B2 bucket `aly-backups` at `s3.us-east-005.backblazeb2.com`.

| Layer                        | Path                  | Schedule                                 | Retention                    |
| ---------------------------- | --------------------- | ---------------------------------------- | ---------------------------- |
| CNPG postgres (WAL + base)   | `cute.haus/cnpg/`     | continuous WAL + daily base at 04:00 UTC | 30d base; WAL kept as needed |
| Longhorn volumes (every PVC) | `cute.haus/longhorn/` | daily at 05:00 UTC                       | 14d per volume               |
| k3s etcd                     | —                     | not wired yet                            | —                            |

Credentials live in [`secrets/b2.yaml`](secrets/b2.yaml) (sops). Wired into:

- `pg-shared-b2` Secret in `cnpg-system` — referenced by CNPG `barmanObjectStore`
- `longhorn-b2` Secret in `longhorn-system` — referenced by Longhorn `defaultBackupStore`

---

## 🔍 Verifying

```bash
# what's actually in B2
rclone tree b2:aly-backups/cute.haus/

# CNPG (in-cluster view)
kubectl get backup.postgresql.cnpg.io -n cnpg-system
kubectl get scheduledbackup           -n cnpg-system

# Longhorn (in-cluster view)
kubectl get backuptarget              -n longhorn-system   # AVAILABLE should be true
kubectl get backup.longhorn.io        -n longhorn-system
kubectl get recurringjob              -n longhorn-system
```

---

## 🩹 Restore: CNPG

CNPG restores by creating a **new** Cluster with `bootstrap.recovery` pointed at
the same B2 target. Apps are cut over by changing their DB connection string
to the new cluster's `-rw` Service.

Reference: <https://cloudnative-pg.io/documentation/current/recovery/>

Minimal example:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: pg-shared-restored
  namespace: cnpg-system
spec:
  instances: 3
  storage:
    storageClass: longhorn-pg
    size: 5Gi
  bootstrap:
    recovery:
      source: pg-shared
  externalClusters:
    - name: pg-shared
      barmanObjectStore:
        destinationPath: s3://aly-backups/cute.haus/cnpg
        endpointURL: https://s3.us-east-005.backblazeb2.com
        s3Credentials:
          accessKeyId: { name: pg-shared-b2, key: KEY_ID }
          secretAccessKey: { name: pg-shared-b2, key: APP_KEY }
```

For point-in-time recovery, add `bootstrap.recovery.recoveryTarget.targetTime`.

---

## 🩹 Restore: Longhorn volume

Cleanest path is restore-as-new-volume, mount it alongside the live PVC, copy
what you need:

1. Longhorn UI → Backup tab → select volume → Backups → restore as new volume.
   Or by CR: <https://longhorn.io/docs/1.11.2/snapshots-and-backups/backup-and-restore/restore-a-backup/>
2. Create a PVC bound to the restored Volume's name, mount from a debug pod.
3. `cp -a` into the live PVC, or swap the live PVC's `spec.volumeName` to the
   restored Volume name.

---

## 🌋 If everything is gone

If we lose enough nodes to break etcd quorum, the cluster has to be rebuilt
from scratch:

1. NixOS + k3s on replacement hardware (see [`nix/hosts/README.md`](nix/hosts/README.md)).
2. `helmfile sync` infra + `cluster-tls` + `pg-shared` (the `needs:` chains
   resolve in correct order).
3. Restore `pg-shared` from B2 — same as the recipe above, but use
   `bootstrap.recovery` instead of the chart's default `initdb`.
4. Restore Longhorn volumes one by one, re-binding each app's PVC by
   `volumeName` before re-deploying the app charts.

This procedure has not been rehearsed end-to-end; it's documented as a
starting point. Worth scheduling a DR drill once the homelab quiets down.
