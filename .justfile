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
    CADDY_FILE="nix/modules/nixos/services/caddy/default.nix"
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

# Regenerate .sops.yaml from keys/*.pub, then re-encrypt every
# secrets/*.yaml. Run after adding or removing a .pub file.
[group('secrets')]
sops-rekey:
    #!/usr/bin/env bash
    set -euo pipefail
    shopt -s nullglob
    user_pubs=(keys/aly_*.pub)
    host_pubs=(keys/root_*.pub)
    {
        cat <<'EOF'
    # Auto-generated by `just sops-rekey` from keys/*.pub.
    # Every recipient can decrypt every secret. To add or remove a
    # machine, add or remove its .pub file and re-run `just sops-rekey`.
    keys:
      # === user keys (aly@<host>) ===
    EOF
        for f in "${user_pubs[@]}"; do
            host=$(basename "$f" .pub); host=${host#aly_}
            age=$(ssh-to-age -i "$f")
            printf '  - &user_aly_%s %s\n' "$host" "$age"
        done
        echo "  # === host keys (root@<host>) ==="
        for f in "${host_pubs[@]}"; do
            host=$(basename "$f" .pub); host=${host#root_}
            age=$(ssh-to-age -i "$f")
            printf '  - &host_%s %s\n' "$host" "$age"
        done
        cat <<'EOF'

    creation_rules:
      - path_regex: ^secrets/.*\.ya?ml$
        key_groups:
          - age:
    EOF
        for f in "${user_pubs[@]}"; do
            host=$(basename "$f" .pub); host=${host#aly_}
            printf '          - *user_aly_%s\n' "$host"
        done
        for f in "${host_pubs[@]}"; do
            host=$(basename "$f" .pub); host=${host#root_}
            printf '          - *host_%s\n' "$host"
        done
    } > .sops.yaml
    echo "regenerated .sops.yaml"
    for f in secrets/*.yaml; do
        echo "rekeying $f"
        sops updatekeys -y "$f"
    done

# Edit a sops-encrypted secrets file. Usage: just sops-edit vaultwarden.yaml
[group('secrets')]
sops-edit FILE:
    sops secrets/{{FILE}}

############################################################################
#
#  Kubes (k3s + helmfile)
#
############################################################################

# Scaffold a new app chart under k8s/charts/<name>. After running, edit the
# values.yaml and add a release block to k8s/helmfile.yaml. See k8s/charts/README.md.
[group('kubes')]
new-app NAME:
    #!/usr/bin/env bash
    set -euo pipefail
    DIR="k8s/charts/{{ NAME }}"
    if [[ -e "$DIR" ]]; then
        echo "$DIR already exists; aborting." >&2
        exit 1
    fi
    mkdir -p "$DIR/templates"
    cat > "$DIR/Chart.yaml" <<EOF
    apiVersion: v2
    name: {{ NAME }}
    description: TODO
    type: application
    version: 0.1.0
    appVersion: "1.0.0"
    dependencies:
      - name: common
        version: 0.1.0
        repository: file://../common
    EOF
    cat > "$DIR/values.yaml" <<'EOF'
    replicaCount: 1
    strategy: Recreate

    image:
      repository: TODO
      tag: latest
      pullPolicy: Always

    resources:
      requests: { cpu: 50m, memory: 64Mi }
      limits:   { cpu: "1", memory: 256Mi }

    ports:
      - name: http
        containerPort: 80

    service:
      type: ClusterIP
      ports:
        - name: http
          port: 80
          targetPort: http

    probes:
      readiness:
        httpGet: { path: /, port: http }
        periodSeconds: 10

    ingress:
      enabled: true
      className: traefik
      routes:
        - host: TODO.cute.haus
          tlsSecret: cute-haus-tls
    EOF
    for kind in deployment service ingress; do
        echo '{{{{- include "common.'"$kind"'" . }}}}' > "$DIR/templates/$kind.yaml"
    done
    helm dependency update "$DIR" >/dev/null
    echo "scaffolded $DIR. next: edit values.yaml and add a release to k8s/helmfile.yaml."
