# Work in shared infrastructure

This repository manages the Backblaze B2 buckets and the Tailscale ACL shared by the cluster repositories. Keep host, Kubernetes, and application changes in Sinnoh, Johto, or Hoenn. Keep shared recovery and operations guides in `docs/`.

`terraform/` contains the OpenTofu configuration. `secrets/` holds its SOPS-encrypted credentials. Every public key in `keys/` is a recipient for every file in `secrets/`.

## Check an OpenTofu change

Run these commands before you apply:

```sh
nix fmt
nix flake check
tofu -chdir=terraform fmt -check
tofu -chdir=terraform plan
```

Run `tofu -chdir=terraform apply` only after you review the plan. The B2 backend does not lock state. Never run concurrent applies.

## Keep secrets out of Git

Do not print decrypted values or commit private keys, OpenTofu state, or saved plans. When `keys/` changes, update every SOPS file with `just sops-rekey` and commit the recipient changes together.
