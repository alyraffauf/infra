{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: {
  options.myNixOs.service = {
    plex = {
      enable = lib.mkEnableOption "Plex media server";
      dataDir = lib.mkOption {
        description = "Data directory to use.";
        default = "/var/lib";
        type = lib.types.str;
      };
    };

    tautulli.enable = lib.mkEnableOption "Tautulli";
  };

  config = lib.mkMerge [
    (lib.mkIf config.myNixOs.service.plex.enable {
      services.plex = {
        enable = true;
        dataDir = "${config.myNixOs.service.plex.dataDir}/plex";

        extraPlugins = [
          (builtins.path {
            name = "Audnexus.bundle";
            path = inputs.audnexus;
          })
          (builtins.path {
            name = "Hama.bundle";
            path = inputs.hama;
          })
        ];

        extraScanners = [
          (builtins.path {
            name = "Absolute-Series-Scanner";
            path = inputs.absolute;
          })
        ];

        openFirewall = true;
      };

      systemd.services.plex.serviceConfig.TimeoutStopSec = 15;
    })

    (lib.mkIf config.myNixOs.service.tautulli.enable {
      services.tautulli = {
        enable = true;
        openFirewall = true;
      };
    })

    (lib.mkIf config.myNixOs.profile.backups.enable {
      myNixOs.profile.backups.jobs = lib.mkMerge [
        (lib.mkIf config.myNixOs.service.plex.enable {
          plex = {
            backupCleanupCommand = "${pkgs.systemd}/bin/systemctl start plex";
            backupPrepareCommand = "${pkgs.systemd}/bin/systemctl stop plex";
            exclude = ["${config.services.plex.dataDir}/Plex Media Server/Plug-in Support/Databases"];
            paths = [config.services.plex.dataDir];
          };
        })

        (lib.mkIf config.myNixOs.service.tautulli.enable {
          tautulli = {
            backupCleanupCommand = "${pkgs.systemd}/bin/systemctl start tautulli";
            backupPrepareCommand = "${pkgs.systemd}/bin/systemctl stop tautulli";
            paths = [config.services.tautulli.dataDir];
          };
        })
      ];
    })
  ];
}
