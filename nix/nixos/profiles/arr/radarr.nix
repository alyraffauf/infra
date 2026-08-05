{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkMerge [
    (lib.mkIf config.myNixOs.profile.arr.enable {
      services.radarr = {
        enable = true;
        dataDir = "${config.myNixOs.profile.arr.dataDir}/radarr/.config/Radarr/";
        openFirewall = true;
      };

      systemd.tmpfiles.rules = [
        "d ${config.services.radarr.dataDir} 0755 radarr radarr"
      ];
    })
    (lib.mkIf (config.myNixOs.profile.arr.enable && config.myNixOs.profile.backups.enable) {
      myNixOs.profile.backups.jobs.radarr = {
        backupCleanupCommand = "${pkgs.systemd}/bin/systemctl start radarr";
        backupPrepareCommand = "${pkgs.systemd}/bin/systemctl stop radarr";
        paths = [config.services.radarr.dataDir];
      };
    })
  ];
}
