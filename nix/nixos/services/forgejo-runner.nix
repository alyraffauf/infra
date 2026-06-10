{self, ...}: {
  flake.modules.nixos.forgejo-runner = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.myForgejoRunner = {
      nativeRunners = lib.mkOption {
        type = lib.types.int;
        default = 1;
        description = "How many native NixOS runners to run.";
      };

      dockerContainers = lib.mkOption {
        type = lib.types.int;
        default = 1;
        description = "How many docker containers to run.";
      };
    };

    config = {
      assertions = [
        {
          assertion = config.services.tailscale.enable;
          message = "We contact Forĝejo over tailscale, but services.tailscale.enable != true.";
        }
      ];

      sops.secrets.act-runner = {
        sopsFile = "${self}/secrets/act-runner.yaml";
        key = "TOKEN";
      };

      services.gitea-actions-runner = let
        arch = lib.replaceStrings ["-"] ["_"] pkgs.stdenv.hostPlatform.system;
      in {
        instances = let
          tokenFile = config.sops.secrets.act-runner.path;
        in {
          alycodes-containers = {
            inherit tokenFile;
            enable = true;
            labels = lib.optional (arch == "aarch64_linux") "ubuntu-24.04-arm:docker://gitea/runner-images:ubuntu-latest" ++ lib.optional (arch == "x86_64_linux") "ubuntu-latest:docker://gitea/runner-images:ubuntu-latest";
            name = "${arch}-${config.networking.hostName}-alycodes-containers";

            settings = {
              container.network = "host";
              runner.capacity = config.myForgejoRunner.dockerContainers;
            };

            url = "https://git.aly.codes";
          };

          alycodes-nixos = {
            inherit tokenFile;
            enable = true;

            hostPackages = with pkgs;
              [bash cachix coreutils curl gawk gitMinimal gnused jq nodejs wget]
              ++ [config.nix.package];

            labels = ["nixos-${arch}:host"];
            name = "${arch}-${config.networking.hostName}-alycodes-nixos";

            settings = {
              container.network = "host";
              runner.capacity = config.myForgejoRunner.nativeRunners;
            };

            url = "https://git.aly.codes";
          };
        };
      };
    };
  };
}
