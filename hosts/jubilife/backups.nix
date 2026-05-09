{config, ...}: {
  services.restic.backups = {
    dizquetv =
      config.mySnippets.restic
      // {
        passwordFile = config.sops.secrets.restic-passwd.path;
        rcloneConfigFile = config.sops.secrets.rclone-b2.path;
        paths = ["/mnt/Data/dizquetv"];
        repository = "rclone:b2:aly-backups/${config.networking.hostName}/dizquetv";
      };

    # syncthing-sync =
    #   config.mySnippets.restic
    #   // {
    #     paths = ["/home/aly/sync"];
    #     repository = "rclone:b2:aly-backups/syncthing/sync";
    #   };
  };
}
