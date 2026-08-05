{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkMerge [
    (lib.mkIf config.myNixOs.profile.arr.enable {
      services.lidarr = {
        enable = true;
        dataDir = "${config.myNixOs.profile.arr.dataDir}/lidarr/.config/Lidarr";
        openFirewall = true;
      };

      systemd.tmpfiles.rules = [
        "d ${config.services.lidarr.dataDir} 0755 lidarr lidarr"
      ];
    })
    (lib.mkIf (config.myNixOs.profile.arr.enable && config.myNixOs.profile.backups.enable) {
      myNixOs.profile.backups.jobs.lidarr = {
        backupCleanupCommand = "${pkgs.systemd}/bin/systemctl start lidarr";
        backupPrepareCommand = "${pkgs.systemd}/bin/systemctl stop lidarr";
        paths = [config.services.lidarr.dataDir];
      };
    })
  ];
}
