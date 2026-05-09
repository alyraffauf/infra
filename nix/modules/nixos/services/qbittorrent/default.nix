{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.myNixOS.services.qbittorrent;
in {
  options.myNixOS.services.qbittorrent = {
    enable = lib.mkEnableOption "qBittorrent headless";

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/qbittorrent";
      description = "The directory where qBittorrent stores its data files.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "qbittorrent";
      description = "User account under which qBittorrent runs.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "qbittorrent";
      description = "Group under which qBittorrent runs.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "qbittorrent web UI port.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "qbittorrent.port to the outside network.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.qbittorrent-nox;
      defaultText = lib.literalExpression "pkgs.qbittorrent-nox";
      description = "The qbittorrent package to use.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.qbittorrent = {
      inherit
        (config.myNixOS.services.qbittorrent)
        openFirewall
        user
        group
        package
        ;

      enable = true;
      profileDir = cfg.dataDir;
      webuiPort = cfg.port;
    };
  };
}
