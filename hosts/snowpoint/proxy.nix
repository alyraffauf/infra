_: let
  tnet = "narwhal-snapper.ts.net";
in {
  services = {
    caddy = {
      email = "alyraffauf@fastmail.com";

      virtualHosts = {
        "navidrome.${tnet}".extraConfig = ''
          bind tailscale/navidrome
          encode zstd gzip
          reverse_proxy snowpoint:4533
        '';

        "photoprism.${tnet}".extraConfig = ''
          bind tailscale/photoprism
          encode zstd gzip
          reverse_proxy jubilife:2342
        '';
      };
    };
  };
}
