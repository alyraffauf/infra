{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkMerge [
    (lib.mkIf config.myNixOs.profile.arr.enable {
      services.prowlarr = {
        enable = true;
        openFirewall = true;
      };
    })
    (lib.mkIf (config.myNixOs.profile.arr.enable && config.myNixOs.profile.backups.enable) {
      myNixOs.profile.backups.jobs.prowlarr = {
        backupCleanupCommand = "${pkgs.systemd}/bin/systemctl start prowlarr";
        backupPrepareCommand = "${pkgs.systemd}/bin/systemctl stop prowlarr";
        paths = [config.services.prowlarr.dataDir];
      };
    })
  ];
}
