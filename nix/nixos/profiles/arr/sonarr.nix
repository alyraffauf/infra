{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkMerge [
    (lib.mkIf config.myNixOs.profile.arr.enable {
      services.sonarr = {
        enable = true;
        dataDir = "${config.myNixOs.profile.arr.dataDir}/sonarr/.config/NzbDrone/";
        openFirewall = true;
      };

      systemd.tmpfiles.rules = [
        "d ${config.services.sonarr.dataDir} 0755 sonarr sonarr"
      ];
    })
    (lib.mkIf (config.myNixOs.profile.arr.enable && config.myNixOs.profile.backups.enable) {
      myNixOs.profile.backups.jobs.sonarr = {
        backupCleanupCommand = "${pkgs.systemd}/bin/systemctl start sonarr";
        backupPrepareCommand = "${pkgs.systemd}/bin/systemctl stop sonarr";
        paths = [config.services.sonarr.dataDir];
      };
    })
  ];
}
