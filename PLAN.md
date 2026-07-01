# Flux GitOps Migration Plan

## Final Step-By-Step Plan

1. **Bootstrap Flux With Option B**
   - Use `flux bootstrap github` now.
   - Bootstrap path: `k8s/flux/system`.
   - Do not change NixOS during this migration.
   - Treat future NixOS/k3s auto-deploy bootstrap as optional hardening later.
   - Ensure there is one root model: `k8s/flux/system` owns the Flux root and references child Flux `Kustomization`s.

2. **Add Flux SOPS Key**
   - Generate a dedicated Flux age keypair.
   - Commit only the public key as `keys/flux_k8s.pub`.
   - Store the private key out-of-band.
   - Create `flux-system/sops-age` manually as a bootstrap artifact.
   - Do not rely on Flux to decrypt/manage its own decryption key.
   - Disaster recovery procedure will be: rebuild k3s, bootstrap Flux, apply `sops-age`, then Flux reconciles encrypted resources.

3. **Update SOPS Policy**
   - Extend `.sops.yaml` generation so `k8s/flux/secrets/*.sops.yaml` encrypts to:
     - existing user keys
     - existing host keys
     - new `flux_k8s` key
   - Keep existing `secrets/*.yaml` encrypted only to user/host keys.
   - Flux must not be able to decrypt host/Terraform/local secrets.
   - Run `just sops-rekey` after updating recipients.

4. **Create Flux Directory Layout**
   - Create:

     ```text
     k8s/flux/
     ├── system/
     ├── sources/
     ├── infra-crds/
     ├── infra-core/
     ├── platform/
     ├── apps/
     ├── external-routes/
     └── secrets/
     ```

   - Keep all first-class k8s Secret manifests in flat `k8s/flux/secrets/`.

5. **Define Flux Layer Graph**
   - Use Flux `Kustomization.dependsOn` between layers:

     ```text
     system -> sources -> infra-crds -> infra-core -> platform -> apps -> external-routes
     ```

   - Use `HelmRelease.dependsOn` only for same-layer release ordering.
   - Set all Flux intervals to `15m`.
   - Use explicit `flux reconcile ...` for immediate deploys.
   - Empty layers carry temporary placeholder ConfigMaps so Flux/Kustomize can
     reconcile them before real resources are migrated. Remove each placeholder
     when that layer gets its first real resource.

6. **Create Flux Sources**
   - Add `GitRepository cute-haus` pointing at the monorepo.
   - Add `HelmRepository` resources for:
     - `grafana`
     - `prometheus-community`
     - `traefik`
     - `longhorn`
     - `cnpg`
     - `tailscale`
     - `jetstack`
     - `nfd`
     - `intel`

7. **Convert Global Values**
   - Convert `k8s/values/global.yaml` into non-secret `ConfigMap cute-haus-global`.
   - Reference it from HelmReleases with `valuesFrom`.
   - Document that this ConfigMap must stay non-secret.
   - Any secret-like value must go into `k8s/flux/secrets/*.sops.yaml`.

8. **Migrate Secrets To First-Class Manifests**
   - For charts that currently render Secrets, create equivalent SOPS-encrypted Kubernetes Secret manifests in `k8s/flux/secrets/`.
   - Delete chart secret templates after the first-class Secret exists.
   - Ensure each Secret is applied in the same or earlier Flux `Kustomization` than its consuming `HelmRelease`.

9. **Apply Secret-Specific Migrations**
   - `longhorn-creds`: move `longhorn-b2` to first-class Secret; keep chart for recurring job, UI ingress, and proxy class.
   - `cert-manager-issuers`: move `cloudflare-api-token` to first-class Secret.
   - `cluster-tls`: move TLS material to first-class `kubernetes.io/tls` Secrets.
   - `pg-shared`: move `pg-shared-b2` and `<role>-pg-creds` to first-class Secrets.
   - `tranquil-pds`: move `tranquil-pds-env` and `atcr-pull` to first-class Secrets.
   - `forward-auth`: move per-app `forward-auth-<app>-env` Secrets to first-class Secrets.
   - App env Secrets: move `<app>-env` Secrets to first-class Secrets.
   - `tailscale-operator`: use `valuesFrom: Secret` because the upstream chart consumes secret values directly.

10. **Preserve Forward-Auth Check**
    - Keep the forward-auth `apps:` declaration plaintext.
    - Move only signing secrets into first-class encrypted Secret manifests.
    - Keep `check-forward-auth.ts` conceptually unchanged.

11. **Convert Helmfile Releases To Flux HelmReleases**
    - Convert releases layer-by-layer.
    - External charts use `HelmRepository`.
    - In-tree charts use `GitRepository` and `chart: ./k8s/charts/<name>`.
    - Inline non-secret values in `spec.values`.
    - Use `valuesFrom` for `cute-haus-global` and the `tailscale-operator` secret values.
    - Do not let Helmfile and Flux manage the same release at the same time.

12. **Smoke Test First**
    - Migrate `watsup` first.
    - Since `cluster-tls` is still Helmfile-managed at that point, omit temporary Flux `dependsOn` for `cluster-tls`.
    - Validate:
      - Flux source reconciliation
      - local chart HelmRelease
      - `helm-controller`
      - manual `just k8s` workflow
      - rollback path

13. **Migrate Layer-By-Layer**
    - After `watsup`, migrate:
      1. `infra-crds`: `cert-manager`, `cnpg`
      2. `infra-core`: `traefik`, `longhorn-creds`, `longhorn`, `tailscale-operator`, NFD, Intel device plugins, `cert-manager-issuers`
      3. `platform`: `pg-shared`, `valkey`, `tika`, `gotenberg`, `cluster-tls`, monitoring
      4. `apps`: app releases, env-only first, multi-secret apps later
      5. `external-routes`: last

14. **Per-Release Cutover Checklist**
    - Create required first-class SOPS Secret manifests.
    - Add or update the `HelmRelease`.
    - Remove the release from `k8s/helmfile.yaml`.
    - Remove obsolete `k8s/values/secrets/<release>.yaml`.
    - Push.
    - Run:

      ```bash
      flux reconcile source git cute-haus -n flux-system
      flux reconcile kustomization <layer> -n flux-system
      ```

    - Verify:

      ```bash
      flux get kustomizations -A
      flux get helmreleases -A
      helm list -A
      kubectl get all -n <namespace>
      ```

15. **Add `just k8s` Manual Workflow**
    - Add one short helper:

      ```bash
      just k8s apply <release>
      just k8s diff <release>
      just k8s suspend <release>
      just k8s resume <release>
      just k8s reconcile <release>
      ```

    - Scope: local in-tree charts only where release name equals `k8s/charts/<release>`.
    - `apply` suspends Flux first, then runs `helm upgrade --install`.
    - `diff` uses `helm diff upgrade --allow-unreleased`.
    - External charts are managed through Flux only.

16. **Update CI And Checks**
    - Keep existing chart render checks.
    - Update `check-release-names.ts` to read Flux `HelmRelease` resources instead of `helmfile.yaml`.
    - Update `check-pinned-images.ts` to derive deployed local charts from Flux `HelmRelease`s.
    - Keep `check-forward-auth.ts` reading plaintext forward-auth app declarations.
    - Add Flux/Kustomize validation:

      ```bash
      kustomize build k8s/flux/system
      kustomize build k8s/flux/sources
      kustomize build k8s/flux/infra-crds
      kustomize build k8s/flux/infra-core
      kustomize build k8s/flux/platform
      kustomize build k8s/flux/apps
      kustomize build k8s/flux/external-routes
      ```

17. **Rollback Strategy**
    - Keep `helmfile.yaml` usable until the final cleanup.
    - If one release fails:

      ```bash
      flux suspend helmrelease <release> -n <namespace>
      ```

    - Re-add the release to Helmfile if needed and apply it manually.
    - For a bad Flux commit, revert the commit and reconcile Flux.
    - Do not delete Helmfile until all releases have been verified under Flux.

18. **Final Cleanup**
    - Delete `k8s/helmfile.yaml`.
    - Delete obsolete `k8s/values/secrets/*.yaml`.
    - Audit for `vals` and `ref+sops://`.
    - Remove `vals` from the devShell if unused.
    - Update docs:
      - `AGENTS.md`
      - `README.md`
      - `k8s/charts/README.md`
    - Clarify that `longhorn-creds` no longer owns credential material despite retaining the release name.

19. **Post-Migration Hardening**
    - Rotate duplicated shared credentials toward one credential per consumer.
    - Optionally migrate Flux bootstrap from Option B to Option A:
      - NixOS writes Flux controller manifests into k3s auto-deploy dir.
      - Flux continues managing app/platform resources from Git.
    - Optionally reorganize legacy `secrets/` later, outside this migration.
