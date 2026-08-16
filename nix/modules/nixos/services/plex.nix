_: {
  flake.nixosModules = {
    plex = {
      config,
      inputs,
      lib,
      pkgs,
      ...
    }: {
      options.myNixOs.service.plex.dataDir = lib.mkOption {
        description = "Data directory to use.";
        default = "/var/lib";
        type = lib.types.str;
      };

      config = {
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

        myNixOs.profile.backups.jobs.plex = {
          backupCleanupCommand = "${pkgs.systemd}/bin/systemctl start plex";
          backupPrepareCommand = "${pkgs.systemd}/bin/systemctl stop plex";
          exclude = ["${config.services.plex.dataDir}/Plex Media Server/Plug-in Support/Databases"];
          paths = [config.services.plex.dataDir];
        };
      };
    };

    tautulli = {
      config,
      pkgs,
      ...
    }: {
      services.tautulli = {
        enable = true;
        openFirewall = true;
      };

      myNixOs.profile.backups.jobs.tautulli = {
        backupCleanupCommand = "${pkgs.systemd}/bin/systemctl start tautulli";
        backupPrepareCommand = "${pkgs.systemd}/bin/systemctl stop tautulli";
        paths = [config.services.tautulli.dataDir];
      };
    };
  };
}
