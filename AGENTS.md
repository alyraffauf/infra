# AGENTS.md

This repository manages B2 buckets and the Tailscale ACL.

- Keep host, Kubernetes, and application changes in `sinnoh`, `johto`, or
  `hoenn`.
- Run `tofu -chdir=terraform plan` before any apply.
- B2 stores OpenTofu state without locking. Never run concurrent applies.
- `secrets/` uses every recipient in `keys/`. Do not print decrypted values.
- Use `just fmt` and `just validate` after OpenTofu edits.
