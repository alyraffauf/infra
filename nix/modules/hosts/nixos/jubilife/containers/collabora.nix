_: {
  flake.nixosModules.jubilife = _: {
    virtualisation.oci-containers.containers.collabora = {
      image = "docker.io/collabora/code:latest@sha256:6b70f91f0b6e9c76f75f162f58ef0a12cf9415d78e14713d33c0318ddc4a2cc0";
      environment = {
        DONT_GEN_SSL_CERT = "true";
        aliasgroup1 = "https://nextcloud\\.cute\\.haus";
        extra_params = "--o:ssl.enable=false --o:ssl.termination=true";
        server_name = "collabora.cute.haus";
      };
      extraOptions = [
        "--cap-add=MKNOD"
        "--memory=4g"
      ];
      ports = ["10.254.0.1:9980:9980"];
    };

    systemd.services.docker-collabora.unitConfig.RequiresMountsFor = ["/mnt/Data"];
  };
}
