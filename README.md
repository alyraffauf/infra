# ❄️ cute.haus

Welcome to **cute.haus**!

This repository contains NixOS configurations, along with whatever custom modules and packages required for [cute.haus](https://cute.haus), my production infrasture running on NixOS and Kubernetes.

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
├── k8s/                     # k3s: helmfile + in-tree charts + vals overlays
│   ├── helmfile.yaml        # release graph (helmfile + helm + vals)
│   ├── charts/              # In-tree helm charts (see k8s/charts/README.md)
│   └── values/              # Per-chart vals refs into ../secrets/
├── secrets/                 # SOPS-encrypted yaml (multi-recipient age)
├── keys/                    # Per-host + per-user age recipients
├── terraform/               # Cloudflare DNS, etc.
└── ansible/                 # Server playbooks (deploy-offline, reboots)
```

---

## 📜 License

This repository is licensed under the **[GNU General Public License](LICENSE.md)**.

---

## ⭐ Stargazers Over Time

[![Stargazers over time](https://starchart.cc/alyraffauf/cute.haus.svg?variant=adaptive)](https://starchart.cc/alyraffauf/cute.haus)

---
