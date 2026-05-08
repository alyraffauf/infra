# just is a command runner, Justfile is very similar to Makefile, but simpler.
############################################################################
#
#  Common recipes
#
############################################################################

# List all recipes.
_default:
    @printf '\033[1;36mnixcfg recipes\033[0m\n\n'
    @printf '\033[1;33mUsage:\033[0m just <recipe> [args...]\n\n'
    @just --list --list-heading $'Available recipes:\n\n'

# Generate {ci,edconfig} files.
[group('flake')]
gen target:
    nix run .#{{ if target == "ci" { "render-workflows" } else if target == "edconfig" { "gen-files" } else { error("unknown target: " + target) } }}

# Update flake inputs.
[group('flake')]
update *inputs:
    nix flake update {{ inputs }} --commit-lock-file

# Update all nixpkgs inputs.
[group('flake')]
update-nixpkgs: (update "nixpkgs")

# Update caddy-tailscale plugin to latest commit (also refreshes hash if stale).
[group('flake')]
update-caddy-tailscale:
    #!/usr/bin/env bash
    set -euo pipefail
    CADDY_FILE="modules/nixos/services/caddy/default.nix"
    RESPONSE=$(curl -sf "https://api.github.com/repos/tailscale/caddy-tailscale/commits?per_page=1")
    SHA=$(echo "$RESPONSE" | grep -m1 '"sha"' | sed 's/.*"sha": *"//;s/".*//')
    SHA12=${SHA:0:12}
    COMMITTER_DATE=$(echo "$RESPONSE" | sed -n '/"committer": {/{n;n;n;s/.*"date": *"//;s/".*//;p;q;}')
    TIMESTAMP=$(echo "$COMMITTER_DATE" | sed 's/[-T:]//g;s/Z//')
    NEW_VERSION="v0.0.0-${TIMESTAMP}-${SHA12}"
    OLD_VERSION=$(grep -o 'caddy-tailscale@[^"]*' "$CADDY_FILE" | sed 's/caddy-tailscale@//')
    VERSION_CHANGED=false
    if [ "$OLD_VERSION" != "$NEW_VERSION" ]; then
        VERSION_CHANGED=true
        echo "Updating caddy-tailscale: $OLD_VERSION -> $NEW_VERSION"
        sed -i "s|caddy-tailscale@[^\"]*|caddy-tailscale@${NEW_VERSION}|" "$CADDY_FILE"
    else
        echo "caddy-tailscale already at latest: $NEW_VERSION"
    fi
    # Always try building with the current hash first; rehash if it fails.
    if nix build .#nixosConfigurations.celestic.config.services.caddy.package 2>/dev/null; then
        if [ "$VERSION_CHANGED" = true ]; then
            git add "$CADDY_FILE"
            git commit -m "caddy: update caddy-tailscale to $NEW_VERSION"
            echo "Done! caddy-tailscale updated to $NEW_VERSION"
        else
            echo "Already up to date."
        fi
        exit 0
    fi
    echo "Hash is stale, determining new hash..."
    sed -i 's|hash = "sha256-[^"]*"|hash = ""|' "$CADDY_FILE"
    BUILD_OUTPUT=$(nix build .#nixosConfigurations.celestic.config.services.caddy.package 2>&1 || true)
    NEW_HASH=$(echo "$BUILD_OUTPUT" | sed -n 's/.*got: *//p' | tr -d ' ')
    if [ -z "$NEW_HASH" ]; then
        echo "Error: could not determine hash from build output."
        echo "$BUILD_OUTPUT"
        exit 1
    fi
    sed -i "s|hash = \"\"|hash = \"${NEW_HASH}\"|" "$CADDY_FILE"
    echo "Updated hash: $NEW_HASH"
    echo "Verifying build..."
    nix build .#nixosConfigurations.celestic.config.services.caddy.package
    git add "$CADDY_FILE"
    if [ "$VERSION_CHANGED" = true ]; then
        git commit -m "caddy: update caddy-tailscale to $NEW_VERSION"
    else
        git commit -m "caddy: update caddy-tailscale hash to $NEW_HASH"
    fi
    echo "Done!"

############################################################################
#
#  Servers
#
############################################################################

# Deploy hosts with nynx.
[group('servers')]
deploy jobs='':
    nynx --operation switch {{ if jobs == "" { "" } else { "--jobs " + jobs } }}

# Pull latest aly.codes OCI on solaceon.
[group('servers')]
update-alycodes:
    ansible-playbook -i ansible/inventory.ini ansible/playbooks/restart-alycodes.yml

# Pull latest morsels OCI on eterna.
[group('servers')]
update-morsels:
    ansible-playbook -i ansible/inventory.ini ansible/playbooks/restart-morsels.yml

# Pull latest myAtmosphere OCI on solaceon.
[group('servers')]
update-myatmosphere:
    ansible-playbook -i ansible/inventory.ini ansible/playbooks/restart-myatmosphere.yml

# Pull latest atbbs OCI on eterna.
[group('servers')]
update-atbbs:
    ansible-playbook -i ansible/inventory.ini ansible/playbooks/restart-atbbs.yml

# Pull latest watsup OCI on solaceon.
[group('servers')]
update-watsup:
    ansible-playbook -i ansible/inventory.ini ansible/playbooks/restart-watsup.yml

# Reboot all servers.
[group('servers')]
reboot:
    ansible-playbook -i ansible/inventory.ini ansible/playbooks/reboot.yml

# Ping all servers.
[group('servers')]
ping:
    ansible-playbook -i ansible/inventory.ini ansible/playbooks/ping.yml

# Queue offline deployment & reboot.
[group('servers')]
deploy-offline:
    nynx --operation boot
    just reboot

############################################################################
#
#  Secrets (sops + age)
#
############################################################################

# Derive this machine's age private key from its ssh ed25519 key, install
# at ~/.config/sops/age/keys.txt. Run once per machine. The corresponding
# public key (age1...) must already be a recipient in .sops.yaml.
[group('secrets')]
sops-bootstrap:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ -f ~/.config/sops/age/keys.txt ]]; then
        echo "~/.config/sops/age/keys.txt already exists; skipping."
        exit 0
    fi
    mkdir -p ~/.config/sops/age
    ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt
    chmod 600 ~/.config/sops/age/keys.txt
    echo "wrote ~/.config/sops/age/keys.txt"
    echo "this machine's age recipient (must be in .sops.yaml):"
    ssh-to-age -i ~/.ssh/id_ed25519.pub

# Re-encrypt every secrets/*.yaml with the current .sops.yaml recipient list.
# Run after editing .sops.yaml to add or remove a machine.
[group('secrets')]
sops-rekey:
    #!/usr/bin/env bash
    set -euo pipefail
    for f in secrets/*.yaml; do
        echo "rekeying $f"
        sops updatekeys -y "$f"
    done

# Edit a sops-encrypted secrets file. Usage: just sops-edit vaultwarden.yaml
[group('secrets')]
sops-edit FILE:
    sops secrets/{{FILE}}
