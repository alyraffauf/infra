_: {
  flake.modules.nixos.arr = {
    config,
    lib,
    options,
    pkgs,
    ...
  }: let
    stop = service: "${pkgs.systemd}/bin/systemctl stop ${service}";
    start = service: "${pkgs.systemd}/bin/systemctl start ${service}";
  in {
    options.myArr.dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib";
      description = "The directory where *arr stores its data files.";
    };

    config = lib.mkMerge [
      {
        services = {
          bazarr = {
            enable = true;
            dataDir = "${config.myArr.dataDir}/bazarr";
            openFirewall = true;
          };

          lidarr = {
            enable = true;
            dataDir = "${config.myArr.dataDir}/lidarr/.config/Lidarr";
            openFirewall = true;
          };

          prowlarr = {
            enable = true;
            openFirewall = true;
          };

          radarr = {
            enable = true;
            dataDir = "${config.myArr.dataDir}/radarr/.config/Radarr/";
            openFirewall = true;
          };

          sonarr = {
            enable = true;
            dataDir = "${config.myArr.dataDir}/sonarr/.config/NzbDrone/";
            openFirewall = true;
          };
        };

        systemd.tmpfiles.rules = [
          "d ${config.services.lidarr.dataDir} 0755 lidarr lidarr"
          "d ${config.services.radarr.dataDir} 0755 radarr radarr"
          "d ${config.services.readarr.dataDir} 0755 readarr readarr"
          "d ${config.services.sonarr.dataDir} 0755 sonarr sonarr"
        ];
      }

      (lib.optionalAttrs (options ? myBackups) {
        myBackups.jobs = {
          bazarr = {
            backupCleanupCommand = start "bazarr";
            backupPrepareCommand = stop "bazarr";
            paths = [config.services.bazarr.dataDir];
          };

          lidarr = {
            backupCleanupCommand = start "lidarr";
            backupPrepareCommand = stop "lidarr";
            paths = [config.services.lidarr.dataDir];
          };

          prowlarr = {
            backupCleanupCommand = start "prowlarr";
            backupPrepareCommand = stop "prowlarr";
            paths = [config.services.prowlarr.dataDir];
          };

          radarr = {
            backupCleanupCommand = start "radarr";
            backupPrepareCommand = stop "radarr";
            paths = [config.services.radarr.dataDir];
          };

          sonarr = {
            backupCleanupCommand = start "sonarr";
            backupPrepareCommand = stop "sonarr";
            paths = [config.services.sonarr.dataDir];
          };
        };
      })
    ];
  };
}
