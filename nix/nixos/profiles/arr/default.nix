{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.myNixOs.profile.arr;
  arrServices = {
    bazarr.dataDir = "${cfg.dataDir}/bazarr";
    lidarr = {
      dataDir = "${cfg.dataDir}/lidarr/.config/Lidarr";
      createDataDir = true;
    };
    prowlarr = {};
    radarr = {
      dataDir = "${cfg.dataDir}/radarr/.config/Radarr/";
      createDataDir = true;
    };
    sonarr = {
      dataDir = "${cfg.dataDir}/sonarr/.config/NzbDrone/";
      createDataDir = true;
    };
  };

  enabledServices =
    lib.mapAttrs (
      _: service:
        {
          enable = true;
          openFirewall = true;
        }
        // lib.optionalAttrs (service ? dataDir) {inherit (service) dataDir;}
    )
    arrServices;

  backupJobs =
    lib.mapAttrs (serviceName: _: {
      backupCleanupCommand = "${pkgs.systemd}/bin/systemctl start ${serviceName}";
      backupPrepareCommand = "${pkgs.systemd}/bin/systemctl stop ${serviceName}";
      paths = [config.services.${serviceName}.dataDir];
    })
    arrServices;

  dataDirectoryServices = lib.filterAttrs (_: service: service.createDataDir or false) arrServices;
in {
  options.myNixOs.profile.arr = {
    enable = lib.mkEnableOption "*arr services";

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib";
      description = "The directory where *arr stores its data files.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services = enabledServices;

      systemd.tmpfiles.rules =
        lib.mapAttrsToList (
          serviceName: service: "d ${service.dataDir} 0755 ${serviceName} ${serviceName}"
        )
        dataDirectoryServices;
    })
    (lib.mkIf (cfg.enable && config.myNixOs.profile.backups.enable) {
      myNixOs.profile.backups.jobs = backupJobs;
    })
  ];
}
