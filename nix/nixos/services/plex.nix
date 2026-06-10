{self, ...}: {
  flake.modules.nixos.plex = {
    config,
    lib,
    options,
    pkgs,
    ...
  }: let
    stop = service: "${pkgs.systemd}/bin/systemctl stop ${service}";
    start = service: "${pkgs.systemd}/bin/systemctl start ${service}";
  in {
    options.myPlex.dataDir = lib.mkOption {
      description = "Data directory to use.";
      default = "/var/lib";
      type = lib.types.str;
    };

    config = lib.mkMerge [
      {
        services.plex = {
          enable = true;
          dataDir = "${config.myPlex.dataDir}/plex";

          extraPlugins = [
            (builtins.path {
              name = "Audnexus.bundle";
              path = self.inputs.audnexus;
            })
            (builtins.path {
              name = "Hama.bundle";
              path = self.inputs.hama;
            })
          ];

          extraScanners = [
            (builtins.path {
              name = "Absolute-Series-Scanner";
              path = self.inputs.absolute;
            })
          ];

          openFirewall = true;
        };

        systemd.services.plex.serviceConfig.TimeoutStopSec = 15;
      }

      (lib.optionalAttrs (options ? myBackups) {
        myBackups.jobs.plex = {
          backupCleanupCommand = start "plex";
          backupPrepareCommand = stop "plex";
          exclude = ["${config.services.plex.dataDir}/Plex Media Server/Plug-in Support/Databases"];
          paths = [config.services.plex.dataDir];
        };
      })
    ];
  };

  flake.modules.nixos.tautulli = {
    config,
    lib,
    options,
    pkgs,
    ...
  }: let
    stop = service: "${pkgs.systemd}/bin/systemctl stop ${service}";
    start = service: "${pkgs.systemd}/bin/systemctl start ${service}";
  in {
    config = lib.mkMerge [
      {
        services.tautulli = {
          enable = true;
          openFirewall = true;
        };
      }

      (lib.optionalAttrs (options ? myBackups) {
        myBackups.jobs.tautulli = {
          backupCleanupCommand = start "tautulli";
          backupPrepareCommand = stop "tautulli";
          paths = [config.services.tautulli.dataDir];
        };
      })
    ];
  };
}
