{
  flake.modules.nixos.arr = {
    config,
    lib,
    ...
  }: {
    options.myArr.dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib";
      description = "The directory where *arr stores its data files.";
    };

    config = {
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
    };
  };

  flake.modules.nixos.backups = {
    config,
    lib,
    pkgs,
    ...
  }: let
    stop = service: "${pkgs.systemd}/bin/systemctl stop ${service}";
    start = service: "${pkgs.systemd}/bin/systemctl start ${service}";
    mkJob = service: {
      backupCleanupCommand = start service;
      backupPrepareCommand = stop service;
      paths = [config.services.${service}.dataDir];
    };
  in {
    config.myBackups.jobs = lib.mkMerge [
      (lib.mkIf config.services.bazarr.enable {bazarr = mkJob "bazarr";})
      (lib.mkIf config.services.lidarr.enable {lidarr = mkJob "lidarr";})
      (lib.mkIf config.services.prowlarr.enable {prowlarr = mkJob "prowlarr";})
      (lib.mkIf config.services.radarr.enable {radarr = mkJob "radarr";})
      (lib.mkIf config.services.sonarr.enable {sonarr = mkJob "sonarr";})
    ];
  };
}
