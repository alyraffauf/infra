# Flux System

Flux was bootstrapped from exported manifests (Option B), not via
`flux bootstrap github`. The manifests in this directory were applied manually
to the cluster. Preserve `layers.yaml` and keep it included from
`kustomization.yaml`; it wires the child reconciliation layers for this repo.

Under the current bootstrap model, `flux-system/sops-age` is a bootstrap
artifact applied out-of-band, not an encrypted Flux-managed Secret.
