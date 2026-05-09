_: {
  security.acme = {
    acceptTerms = true;
    defaults.email = "alyraffauf@fastmail.com";
  };

  services = {
    caddy = {
      email = "alyraffauf@fastmail.com";

      virtualHosts = {
        "morsels.blue" = {
          extraConfig = ''
            encode gzip zstd
            reverse_proxy eterna:8484
          '';

          serverAliases = ["www.morsels.blue"];
        };
      };
    };
  };
}
