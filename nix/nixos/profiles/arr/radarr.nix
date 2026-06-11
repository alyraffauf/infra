{
  flake.modules.nixos = {
    arr = {config, ...}: {
      config = {
        services.radarr = {
          enable = true;
          dataDir = "${config.myArr.dataDir}/radarr/.config/Radarr/";
          openFirewall = true;
        };

        systemd.tmpfiles.rules = [
          "d ${config.services.radarr.dataDir} 0755 radarr radarr"
        ];
      };
    };

    backups = {
      config,
      lib,
      pkgs,
      ...
    }: {
      config.myBackups.jobs = lib.mkIf config.services.radarr.enable {
        radarr = {
          backupCleanupCommand = "${pkgs.systemd}/bin/systemctl start radarr";
          backupPrepareCommand = "${pkgs.systemd}/bin/systemctl stop radarr";
          paths = [config.services.radarr.dataDir];
        };
      };
    };
  };
}
