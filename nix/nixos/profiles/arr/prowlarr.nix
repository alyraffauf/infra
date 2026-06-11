{
  flake.modules.nixos = {
    arr = {
      config.services.prowlarr = {
        enable = true;
        openFirewall = true;
      };
    };

    backups = {
      config,
      lib,
      pkgs,
      ...
    }: {
      config.myBackups.jobs = lib.mkIf config.services.prowlarr.enable {
        prowlarr = {
          backupCleanupCommand = "${pkgs.systemd}/bin/systemctl start prowlarr";
          backupPrepareCommand = "${pkgs.systemd}/bin/systemctl stop prowlarr";
          paths = [config.services.prowlarr.dataDir];
        };
      };
    };
  };
}
