# Shared infrastructure

`infra` holds the shared account-level configuration: Backblaze B2 buckets and
the Tailscale tailnet ACL. It does not run a cluster.

Sinnoh runs public services. Johto runs home services. Hoenn configures
personal machines. Their NixOS hosts, Kubernetes manifests, application
secrets, and deployment automation stay there.

The Git history still has the former all-in-one configuration.

## Layout

- `terraform/` contains the shared state and provider configuration.
- `secrets/` contains the encrypted B2 and Tailscale credentials.
- `docs/` contains runbooks.

## Runbooks

- [Change OpenTofu](docs/change-opentofu.md)
- [Change SOPS recipients](docs/sops.md)
