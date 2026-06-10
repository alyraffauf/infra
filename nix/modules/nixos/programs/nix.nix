{
  config,
  lib,
  ...
}: let
  buildMachines = [
    {
      hostName = "jubilife";
      maxJobs = 12;
      protocol = "ssh-ng";
      speedFactor = 5;
      sshKey = "/etc/ssh/ssh_host_ed25519_key";
      sshUser = "nixbuild";
      supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
      systems = ["x86_64-linux"];
    }
  ];

  isBuildMachine = let buildHosts = lib.map (m: m.hostName) buildMachines; in lib.elem config.networking.hostName buildHosts;
in {
  options.myNixOS.programs.nix.enable = lib.mkEnableOption "sane nix configuration";

  config = lib.mkIf config.myNixOS.programs.nix.enable {
    nix = {
      buildMachines = lib.mkIf config.services.tailscale.enable (
        lib.filter (m: m.hostName != config.networking.hostName)
        buildMachines
      );

      distributedBuilds = true;

      gc = {
        automatic = true;

        options =
          if isBuildMachine
          then "--delete-older-than 20d"
          else "--delete-older-than 3d";

        persistent = true;
        randomizedDelaySec = "60min";
      };

      extraOptions = ''
        min-free = ${toString (1 * 1024 * 1024 * 1024)}   # 1 GiB
        max-free = ${toString (5 * 1024 * 1024 * 1024)}   # 5 GiB
      '';

      optimise = {
        automatic = true;
        persistent = true;
        randomizedDelaySec = "60min";
      };

      settings = {
        builders-use-substitutes = true;

        experimental-features = [
          "fetch-closure"
          "flakes"
          "nix-command"
        ];

        substituters = [
          "https://cache.nixos.org/"
          "https://alyraffauf.cachix.org"
          "https://catppuccin.cachix.org"
          "https://chaotic-nyx.cachix.org/"
          "https://cutehaus.cachix.org"
          "https://nix-community.cachix.org"
        ];

        trusted-public-keys = [
          "alyraffauf.cachix.org-1:GQVrRGfjTtkPGS8M6y7Ik0z4zLt77O0N25ynv2gWzDM="
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
          "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8"
          "cutehaus.cachix.org-1:KiifTsseQBitoaHH8rkDUDwzyz9akLeOM+K+e2eK8dA="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];

        trusted-users = ["aly" "@admin" "@wheel" "nixbuild"];
      };
    };

    programs.nix-ld.enable = true;

    # Only create the nixbuild user (and its group) on build machines
    users.users.nixbuild = lib.mkIf isBuildMachine {
      uid = 1999;
      isNormalUser = true;
      createHome = false;
      group = "nixbuild";

      openssh.authorizedKeys.keyFiles = config.myNixOS.sshKeyFiles.aly ++ config.myNixOS.sshKeyFiles.root;
    };

    users.groups.nixbuild = lib.mkIf isBuildMachine {};

    myNixOS.programs.njust.recipes.nix = ''
      # Garbage collect Nix store
      [group('nix')]
      gc-nix days="3":
          @echo "Cleaning up Nix generations older than {{days}} days..."
          sudo nix-collect-garbage --delete-older-than {{days}}d

      # Optimize Nix store
      [group('nix')]
      optimize-nix:
          @echo "Optimizing Nix store..."
          sudo nix-store --optimise

      # Free space from Nix store
      [group('nix')]
      cleanup-nix: gc-nix && optimize-nix

      # Repair Nix store
      [group('nix')]
      repair-nix:
          sudo nix-store --repair --verify --check-contents
    '';
  };
}
