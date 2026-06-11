{
  flake.modules.nixos = {
    arr = {config, ...}: {
      config.services.bazarr = {
        enable = true;
        dataDir = "${config.myArr.dataDir}/bazarr";
        openFirewall = true;
      };
    };

    backups = {
      config,
      lib,
      pkgs,
      ...
    }: {
      config.myBackups.jobs = lib.mkIf config.services.bazarr.enable {
        bazarr = {
          backupCleanupCommand = "${pkgs.systemd}/bin/systemctl start bazarr";
          backupPrepareCommand = "${pkgs.systemd}/bin/systemctl stop bazarr";
          paths = [config.services.bazarr.dataDir];
        };
      };
    };
  };
}
