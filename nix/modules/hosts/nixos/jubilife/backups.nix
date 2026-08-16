_: {
  flake.nixosModules.jubilife = {config, ...}: {
    myNixOs.profile.backups.jobs = let
      dataDirectory = "/mnt/Data";
    in {
      immich.paths = [
        "${dataDirectory}/immich/library"
        "${dataDirectory}/immich/profile"
        "${dataDirectory}/immich/upload"
        "${dataDirectory}/immich/backups"
        "${dataDirectory}/immich/postgres"
      ];
      garage.paths = ["${dataDirectory}/garage"];
      nextcloud.paths = ["${dataDirectory}/nextcloud/html"];
      paperless.paths = ["${dataDirectory}/paperless"];
      plex = {
        exclude = ["${dataDirectory}/plex/Library/Application Support/Plex Media Server/Plug-in Support/Databases"];
        paths = ["${dataDirectory}/plex"];
      };
      syncthing-roms = {
        paths = [config.myNixOs.service.syncthing.romsPath];
        repository = "rclone:b2:aly-backups/syncthing/roms";
      };
      syncthing-sync = {
        paths = ["/home/aly/sync"];
        repository = "rclone:b2:aly-backups/syncthing/sync";
      };
    };
  };
}
