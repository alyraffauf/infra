_: {
  flake.nixosModules.eterna = {config, ...}: {
    myNixOs.profile.backups.jobs = {
      syncthing-sync = {
        paths = ["/home/aly/sync"];
        repository = "rclone:b2:aly-backups/syncthing/sync";
      };
      syncthing-roms = {
        paths = [config.myNixOs.service.syncthing.romsPath];
        repository = "rclone:b2:aly-backups/syncthing/roms";
      };
    };
  };
}
