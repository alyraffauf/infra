_: {
  flake.modules.nixos.qbittorrent = {
    config,
    lib,
    options,
    pkgs,
    ...
  }: let
    cfg = config.myQbittorrent;
    stop = service: "${pkgs.systemd}/bin/systemctl stop ${service}";
    start = service: "${pkgs.systemd}/bin/systemctl start ${service}";
  in {
    options.myQbittorrent = {
      dataDir = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/qbittorrent";
      };

      user = lib.mkOption {
        type = lib.types.str;
        default = "qbittorrent";
      };
      group = lib.mkOption {
        type = lib.types.str;
        default = "qbittorrent";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 8080;
      };
      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.qbittorrent-nox;
        defaultText = lib.literalExpression "pkgs.qbittorrent-nox";
      };
    };

    config = lib.mkMerge [
      {
        services.qbittorrent = {
          inherit (cfg) openFirewall user group package;
          enable = true;
          profileDir = cfg.dataDir;
          webuiPort = cfg.port;
        };
      }

      (lib.optionalAttrs (options ? myBackups) {
        myBackups.jobs.qbittorrent = {
          backupCleanupCommand = start "qbittorrent";
          backupPrepareCommand = stop "qbittorrent";
          paths = [config.services.qbittorrent.profileDir];
        };
      })
    ];
  };
}
