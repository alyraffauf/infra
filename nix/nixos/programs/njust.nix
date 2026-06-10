_: {
  flake.modules.nixos.njust = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.myNjust;

    defaultRecipes = {
      system = ''
        # Show system info
        [group('system')]
        info:
            @echo "Hostname: $(hostname)"
            @echo "NixOS Version: $(nixos-version)"
            @echo "Kernel: $(uname -r)"
            @echo "Generation: $(sudo nix-env --list-generations -p /nix/var/nix/profiles/system | tail -1 | awk '{print $1}')"
            @echo "Revision: $(nixos-version --json | jq -r '.configurationRevision // "unknown"')"
      '';

      updates = ''
        # Update everything
        [group('system')]
        update: update-nixos update-nix-profile

        # Update NixOS system
        [group('nix')]
        update-nixos action="switch":
            @echo "Updating NixOS..."
            sudo nixos-rebuild {{action}} --flake "${config.myFlakeUrl}"

        # Update Nix user profile
        [group('nix')]
        update-nix-profile:
            @echo "Updating Nix user profile..."
            nix profile upgrade --all
      '';

      secureboot = ''
        # Check Secure Boot status
        [group('secureboot')]
        sb-status:
            sudo bootctl status

        # Generate Secure Boot keys
        [group('secureboot')]
        gen-sb-keys:
            @echo "Generating Secure Boot keys..."
            sudo sbctl create-keys

        # Enroll Secure Boot keys
        [group('secureboot')]
        enroll-sb-keys:
            sudo sbctl enroll-keys --microsoft
      '';

      full-disk-encryption = ''
        # List encrypted volumes
        [group('encryption')]
        fde-status:
            lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT,TYPE,UUID | grep crypt

        # Enable TPM2 disk unlock
        [group('encryption')]
        [confirm("Verify Secure Boot is active before continuing!")]
        enable-tpm2-unlock crypt="/dev/nvme0n1p2":
            sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+2+7+12 --wipe-slot=tpm2 {{crypt}}

        # Enable FIDO2 disk unlock
        [group('encryption')]
        enable-fido2-unlock crypt="/dev/nvme0n1p2":
            sudo systemd-cryptenroll --fido2-device=auto {{crypt}}
      '';
    };

    recipes = config.myRecipes // lib.optionalAttrs cfg.defaultRecipes defaultRecipes;

    mergedJustfileContent = ''
      _default:
          @printf '\033[1;36mnjust\033[0m\n'
          @printf 'Just-based recipe runner for NixOS.\n\n'
          @printf '\033[1;33mUsage:\033[0m njust <recipe> [args...]\n\n'
          @njust --list --list-heading $'Available recipes:\n\n'

      ${lib.concatStringsSep "\n" (lib.attrValues recipes)}
    '';

    validatedJustfile =
      pkgs.runCommand "njust-justfile-validated" {
        nativeBuildInputs = [pkgs.just];
        preferLocalBuild = true;
      } ''
        echo ${lib.escapeShellArg mergedJustfileContent} > justfile

        echo "Validating njust justfile syntax..."
        just --justfile justfile --summary >/dev/null || {
          echo "ERROR: njust justfile has syntax errors!"
          echo "Justfile content:"
          cat justfile
          exit 1
        }

        cp justfile $out
        echo "njust justfile validation passed"
      '';

    njustScript = pkgs.writeShellApplication {
      name = "njust";
      runtimeInputs = [pkgs.jq pkgs.just];
      text = ''
        exec just --working-directory "$PWD" --justfile ${validatedJustfile} "$@"
      '';
    };
  in {
    options.myNjust = {
      defaultRecipes = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
    };

    config.environment.systemPackages = [njustScript];
  };
}
