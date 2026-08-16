_: {
  flake.nixosModules.default = {
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

    isBuildMachine = lib.elem config.networking.hostName (lib.map (m: m.hostName) buildMachines);
  in {
    config = lib.mkMerge [
      {
        nix = {
          buildMachines = lib.mkIf config.services.tailscale.enable (
            lib.filter (m: m.hostName != config.networking.hostName) buildMachines
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
            min-free = ${toString (1 * 1024 * 1024 * 1024)}
            max-free = ${toString (5 * 1024 * 1024 * 1024)}
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
              "https://cutehaus.cachix.org"
            ];

            trusted-public-keys = [
              "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
              "cutehaus.cachix.org-1:KiifTsseQBitoaHH8rkDUDwzyz9akLeOM+K+e2eK8dA="
            ];

            trusted-users = ["aly" "@admin" "@wheel" "nixbuild"];
          };
        };

        programs.nix-ld.enable = true;

        users.users.nixbuild = lib.mkIf isBuildMachine {
          uid = 1999;
          isNormalUser = true;
          createHome = false;
          group = "nixbuild";
        };

        users.groups.nixbuild = lib.mkIf isBuildMachine {};
      }

      (lib.mkIf isBuildMachine {
        mySshKeys.authorizedUsers.nixbuild = ["aly" "root"];
      })
    ];
  };
}
