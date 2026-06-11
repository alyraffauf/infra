{
  flake.modules.nixos = {
    arr = {config, ...}: {
      config = {
        services.lidarr = {
          enable = true;
          dataDir = "${config.myArr.dataDir}/lidarr/.config/Lidarr";
          openFirewall = true;
        };

        systemd.tmpfiles.rules = [
          "d ${config.services.lidarr.dataDir} 0755 lidarr lidarr"
        ];
      };
    };

    backups = {
      config,
      lib,
      pkgs,
      ...
    }: {
      config.myBackups.jobs = lib.mkIf config.services.lidarr.enable {
        lidarr = {
          backupCleanupCommand = "${pkgs.systemd}/bin/systemctl start lidarr";
          backupPrepareCommand = "${pkgs.systemd}/bin/systemctl stop lidarr";
          paths = [config.services.lidarr.dataDir];
        };
      };
    };
  };
}
