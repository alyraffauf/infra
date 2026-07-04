# ❄️ cute.haus

Welcome to **cute.haus**!

This repository contains NixOS, K8s, and Ansible configurations, along with whatever custom modules and packages required for [cute.haus](https://cute.haus), my production infrastructure running NixOS+Kubernetes.

---

![](./_img/glance.png)

---

## 📂 Repository Structure

```plaintext
.
├── flake.nix                # Flake entry point
├── nix/                     # NixOS + flake modules
│   ├── hosts/               # NixOS host configurations
│   └── modules/             # NixOS / flake modules
├── k8s/                     # k3s: Flux + in-tree Helm charts
│   ├── flux/                # GitOps release graph (Flux Kustomizations/HelmReleases)
│   ├── charts/              # In-tree helm charts (see k8s/charts/README.md)
│   └── values/              # Shared non-secret Helm values
├── secrets/                 # SOPS-encrypted yaml (multi-recipient age)
├── keys/                    # Per-host + per-user age recipients
├── terraform/               # Cloudflare DNS, etc.
└── ansible/                 # Server playbooks (deploy-offline, reboots)
```

---

## 📜 License

This repository is licensed under the **[GNU General Public License](LICENSE.md)**.

---
