# Flux Secrets

First-class Kubernetes Secret manifests managed by Flux live here as
SOPS-encrypted `*.sops.yaml` files. The Flux age recipient may decrypt this
directory only; legacy `secrets/*.yaml` remain host/user-only.

The `flux-system/sops-age` private key Secret is a bootstrap artifact. Do not
store that private key in this repository.

This directory is reconciled as its own Flux layer before chart layers, so
first-class Secrets exist before HelmReleases that reference them.
