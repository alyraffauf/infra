# ❄️ cute.haus

Welcome to **cute.haus**!

This repository contains NixOS and home-manager configurations, along with whatever custom modules and packages required for [cute.haus](https://cute.haus), my homelab cluster.

---

![](./_img/glance.png)

---

## 🔗 Related Flakes

- [nixcfg](https://github.com/alyraffauf/cute.haus): My (non-server) NixOS, nix-darwin, and home-manager configurations.
- [flake](https://github.com/alyraffauf/flake): Fully featured flake template for NixOS, nix-darwin, home-manager configurations, and software projects.
- [fontix](https://github.com/alyraffauf/fontix): Home-manager modules for setting consistent fonts and sizing across applications.
- [safari](https://github.com/alyraffauf/safari): Shell configuration used in this repository.
- [snippets](https://github.com/alyraffauf/snippets): Reusable Nix snippets used across multiple repositories.

---

## 📂 Repository Structure

```plaintext
.
├── flake.nix                # Flake entry point
├── nix/                     # NixOS + home-manager + flake modules
│   ├── homes/               # home-manager configurations
│   ├── hosts/               # NixOS host configurations
│   └── modules/             # NixOS / home-manager / flake modules
├── k8s/                     # k3s: helmfile + in-tree charts + vals overlays
│   ├── helmfile.yaml        # release graph (helmfile + helm + vals)
│   ├── charts/              # In-tree helm charts (see k8s/charts/README.md)
│   └── values/              # Per-chart vals refs into ../secrets/
├── secrets/                 # SOPS-encrypted yaml (multi-recipient age)
├── keys/                    # Per-host + per-user age recipients
├── terraform/               # Cloudflare DNS, etc.
├── ansible/                 # Server playbooks (deploy-offline, reboots)
└── BACKUPS.md               # B2 backup + restore runbook (CNPG + Longhorn)
```

---

## 🤝 Contributing

While this is a personal project, I’m open to feedback or suggestions.\
Feel free to open an issue or share ideas that could improve this setup!

---

## 📜 License

This repository is licensed under the **[GNU General Public License](LICENSE.md)**.

---

## ⭐ Stargazers Over Time

[![Stargazers over time](https://starchart.cc/alyraffauf/cute.haus.svg?variant=adaptive)](https://starchart.cc/alyraffauf/cute.haus)

---
