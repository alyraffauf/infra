{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkMerge [
    (lib.mkIf config.myNixOs.profile.arr.enable {
      services.bazarr = {
        enable = true;
        dataDir = "${config.myNixOs.profile.arr.dataDir}/bazarr";
        openFirewall = true;
      };
    })
    (lib.mkIf (config.myNixOs.profile.arr.enable && config.myNixOs.profile.backups.enable) {
      myNixOs.profile.backups.jobs.bazarr = {
        backupCleanupCommand = "${pkgs.systemd}/bin/systemctl start bazarr";
        backupPrepareCommand = "${pkgs.systemd}/bin/systemctl stop bazarr";
        paths = [config.services.bazarr.dataDir];
      };
    })
  ];
}
