# 🖥️ Hosts

This directory contains the NixOS configurations for each of my devices. Each subdirectory corresponds to a specific host, encapsulating its unique setup and specifications.

---

## 📂 Directory Structure

The `hosts/` directory is organized as follows:

```plaintext
hosts/
├── celestic/      # Hetzner VPS
├── eterna/        # Beelink Mini S12 Pro
├── jubilife/      # Custom Mini-ITX NAS
├── snowpoint/     # Netcup VPS
├── solaceon/      # Hetzner VPS
└── twinleaf/      # Minimal installation ISO
```

---

## 🛠️ Provisioning New Devices

1. **Create host configuration**: duplicate an existing host directory under `hosts/` and rename it. Update `default.nix`, `disko.nix`, `hardware.nix`, etc. to match the device.

1. **Register the host**: add it to `nixosConfigurations` in `nix/modules/flake/nixos.nix`.

1. **Install NixOS** on the device using this flake. Secrets will not decrypt on first boot until the host's age key is a recipient.

1. **Add SSH host key as a sops recipient**: copy `/etc/ssh/ssh_host_ed25519_key.pub` from the new device into `keys/root_$HOSTNAME.pub`, then run `just sops-rekey` to regenerate `.sops.yaml` and re-encrypt every secret.

1. **Rebuild** on the new device. Secrets land at `/run/secrets/` (sops-nix).

1. **(Optional) Add a user key**: drop `~/.ssh/id_ed25519.pub` from the new device into `keys/$USER_$HOSTNAME.pub` and re-run `just sops-rekey` so the user can decrypt secrets too.

---
