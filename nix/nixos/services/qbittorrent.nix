{
  flake.modules.nixos.qbittorrent = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.myQbittorrent;
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
    ];
  };

  flake.modules.nixos.backups = {
    config,
    lib,
    pkgs,
    ...
  }: let
    stop = service: "${pkgs.systemd}/bin/systemctl stop ${service}";
    start = service: "${pkgs.systemd}/bin/systemctl start ${service}";
  in {
    config.myBackups.jobs.qbittorrent = lib.mkIf config.services.qbittorrent.enable {
      backupCleanupCommand = start "qbittorrent";
      backupPrepareCommand = stop "qbittorrent";
      paths = [config.services.qbittorrent.profileDir];
    };
  };
}
