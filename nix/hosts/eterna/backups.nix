{config, ...}: let
  restic =
    config.mySnippets.restic
    // {
      passwordFile = config.sops.secrets.restic-passwd.path;
      rcloneConfigFile = config.sops.secrets.rclone-b2.path;
    };
in {
  services.restic.backups = {
    syncthing-sync =
      restic
      // {
        paths = ["/home/aly/sync"];
        repository = "rclone:b2:aly-backups/syncthing/sync";
      };

    syncthing-roms =
      restic
      // {
        paths = [config.myNixOS.services.syncthing.romsPath];
        repository = "rclone:b2:aly-backups/syncthing/roms";
      };
  };
}
