_: {
  flake.nixosModules.jubilife = _: {
    virtualisation.oci-containers.containers.slingshot = {
      image = "ghcr.io/alyraffauf/slingshot:latest@sha256:6e3a2860f0c4aa98e6f95f9ff6a7d9eb61266f2272e3eaeb6de32ba221b20e38";
      environment = {
        SLINGSHOT_CACHE_DIR = "/cache";
        SLINGSHOT_IDENTITY_CACHE_DISK_DB = "2";
        SLINGSHOT_IDENTITY_CACHE_MEMORY_MB = "64";
        SLINGSHOT_JETSTREAM = "wss://jetstream1.us-east.bsky.network/subscribe";
        SLINGSHOT_RECORD_CACHE_DISK_DB = "4";
        SLINGSHOT_RECORD_CACHE_MEMORY_MB = "256";
      };
      extraOptions = [
        "--cpus=2"
        "--memory=2g"
        "--tmpfs=/cache:rw,size=8g,uid=65532,gid=65532"
        "--ulimit=nofile=8192:8192"
      ];
      ports = ["10.254.0.1:8765:8080"];
    };
  };
}
