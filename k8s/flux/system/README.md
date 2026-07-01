# Flux System

`flux bootstrap github --path=k8s/flux/system` installs Flux and may generate
or update files in this directory. Preserve `layers.yaml` and keep it included
from `kustomization.yaml`; it wires the child reconciliation layers for this
repo.

Under the current bootstrap model, `flux-system/sops-age` is a bootstrap
artifact applied out-of-band, not an encrypted Flux-managed Secret.
