{
  flake.modules.nixos.atbbs = {
    config,
    lib,
    ...
  }: {
    options.myAtbbs = {
      port = lib.mkOption {
        description = "Port to listen on.";
        default = 8582;
        type = lib.types.int;
      };

      telnetPort = lib.mkOption {
        description = "Port to listen on for telnet.";
        default = 2323;
        type = lib.types.int;
      };
    };

    config = {
      networking.firewall.allowedTCPPorts = [
        config.myAtbbs.port
        config.myAtbbs.telnetPort
      ];

      virtualisation.oci-containers.containers = {
        atbbs = {
          extraOptions = ["--pull=always"];
          image = "ghcr.io/alyraffauf/atbbs";
          environment.PUBLIC_URL = "https://atbbs.xyz";
          ports = ["0.0.0.0:${toString config.myAtbbs.port}:80"];
        };

        atbbs-telnet = {
          extraOptions = ["--pull=always"];
          image = "ghcr.io/alyraffauf/atbbs-telnet";
          ports = ["0.0.0.0:${toString config.myAtbbs.telnetPort}:2323"];
        };
      };
    };
  };
}
