_: {
  myNixOs.profile.backups.jobs.dizquetv.paths = ["/mnt/Data/dizquetv"];

  systemd.tmpfiles.rules = [
    "z /mnt/Data 0755 root root - -"
    "d /mnt/Data/dizquetv 0755 root root"
    "d /mnt/Data/arm/home 0755 1000 1000 - -"
    "d /mnt/Data/arm/config 0755 1000 1000 - -"
    "d /mnt/Data/arm 0755 1000 1000 - -"
    "d /mnt/Data/jellyfin 0700 1000 1000 - -"
    "d /mnt/Data/plex 0755 1000 1000 - -"
    "d /mnt/Data/garage 0750 garage garage - -"
    "d /mnt/Data/garage/meta 0700 garage garage - -"
    "d /mnt/Data/garage/data 0700 garage garage - -"
    "d /mnt/Data/immich/ml-cache 0755 root root - -"
    "d /mnt/Data/nextcloud/html 0750 33 33 - -"
    "d /mnt/Data/paperless 0750 1000 1000 - -"
    "d /mnt/Data/paperless/data 0750 1000 1000 - -"
    "d /mnt/Data/paperless/consume 0750 1000 1000 - -"
    "d /mnt/Data/paperless/media 0750 1000 1000 - -"
  ];

  virtualisation.oci-containers.containers.dizquetv = {
    image = "vexorian/dizquetv:latest";
    extraOptions = ["--pull=always"];
    ports = ["0.0.0.0:8000:8000"];
    volumes = [
      "/mnt/Data/dizquetv:/home/node/app/.dizquetv"
      "/etc/localtime:/etc/localtime:ro"
    ];
  };
}
