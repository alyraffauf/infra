{
  flake.modules.nixos = {
    arr = {config, ...}: {
      config = {
        services.sonarr = {
          enable = true;
          dataDir = "${config.myArr.dataDir}/sonarr/.config/NzbDrone/";
          openFirewall = true;
        };

        systemd.tmpfiles.rules = [
          "d ${config.services.sonarr.dataDir} 0755 sonarr sonarr"
        ];
      };
    };

    backups = {
      config,
      lib,
      pkgs,
      ...
    }: {
      config.myBackups.jobs = lib.mkIf config.services.sonarr.enable {
        sonarr = {
          backupCleanupCommand = "${pkgs.systemd}/bin/systemctl start sonarr";
          backupPrepareCommand = "${pkgs.systemd}/bin/systemctl stop sonarr";
          paths = [config.services.sonarr.dataDir];
        };
      };
    };
  };
}
