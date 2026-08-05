{
  config,
  lib,
  ...
}: {
  options.myNixOs.service.atbbs = {
    enable = lib.mkEnableOption "ATBBS services";

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

  config = lib.mkIf config.myNixOs.service.atbbs.enable {
    networking.firewall.allowedTCPPorts = [
      config.myNixOs.service.atbbs.port
      config.myNixOs.service.atbbs.telnetPort
    ];

    virtualisation.oci-containers.containers = {
      atbbs = {
        extraOptions = ["--pull=always"];
        image = "ghcr.io/alyraffauf/atbbs";
        environment.PUBLIC_URL = "https://atbbs.xyz";
        ports = ["0.0.0.0:${toString config.myNixOs.service.atbbs.port}:80"];
      };

      atbbs-telnet = {
        extraOptions = ["--pull=always"];
        image = "ghcr.io/alyraffauf/atbbs-telnet";
        ports = ["0.0.0.0:${toString config.myNixOs.service.atbbs.telnetPort}:2323"];
      };
    };
  };
}
