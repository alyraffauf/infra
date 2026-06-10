{
  config,
  lib,
  pkgs,
  self,
  ...
}: let
  cfg = config.myNixOS.profiles.b2-mounts;

  b2Options = [
    "allow_other"
    "args2env"
    "cache-dir=${cfg.cacheDir}"
    "config=${config.sops.secrets.b2-mount-rclone.path}"
    "dir-cache-time=1h"
    "nodev"
    "nofail"
    "vfs-cache-mode=full"
    "vfs-write-back=10s"
    "x-systemd.after=network-online.target"
    "x-systemd.automount"
  ];

  b2ProfileOptions = {
    audio = [
      "buffer-size=128M"
      "vfs-cache-max-age=168h"
      "vfs-cache-max-size=${cfg.audioCacheSize}"
      "vfs-read-ahead=${cfg.audioReadAhead}"
    ];

    video = [
      "buffer-size=512M"
      "vfs-cache-max-age=336h"
      "vfs-cache-max-size=${cfg.videoCacheSize}"
      "vfs-read-ahead=${cfg.videoReadAhead}"
    ];
  };

  mkB2Mount = name: remote: profile: {
    "/mnt/Backblaze/${name}" = {
      device = "b2:${remote}";
      fsType = "rclone";
      options = b2Options ++ b2ProfileOptions.${profile};
    };
  };

  allShares = {
    Anime = mkB2Mount "Anime" "aly-anime" "video";
    Audiobooks = mkB2Mount "Audiobooks" "aly-audiobooks" "audio";
    Movies = mkB2Mount "Movies" "aly-movies" "video";
    Music = mkB2Mount "Music" "aly-music" "audio";
    Shows = mkB2Mount "Shows" "aly-shows" "video";
  };
in {
  options.myNixOS.profiles.b2-mounts = {
    enable = lib.mkEnableOption "Backblaze B2 rclone filesystem mounts";

    cacheDir = lib.mkOption {
      description = "Directory for rclone VFS cache.";
      example = "/mnt/Data/.rclone-cache";
      type = lib.types.str;
    };

    audioCacheSize = lib.mkOption {
      description = "VFS cache max size for audio shares.";
      default = "15G";
      type = lib.types.str;
    };

    videoCacheSize = lib.mkOption {
      description = "VFS cache max size for video shares.";
      default = "50G";
      type = lib.types.str;
    };

    audioReadAhead = lib.mkOption {
      description = "VFS read-ahead for audio shares.";
      default = "1G";
      type = lib.types.str;
    };

    videoReadAhead = lib.mkOption {
      description = "VFS read-ahead for video shares.";
      default = "3G";
      type = lib.types.str;
    };

    shares = lib.mkOption {
      description = "Which B2 shares to mount.";
      default = ["Anime" "Audiobooks" "Movies" "Music" "Shows"];
      type = lib.types.listOf (lib.types.enum ["Anime" "Audiobooks" "Movies" "Music" "Shows"]);
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.b2-mount-rclone = {
      sopsFile = "${self}/secrets/b2.yaml";
      key = "rclone_config";
    };

    environment.systemPackages = [pkgs.rclone];
    fileSystems = builtins.foldl' (a: b: a // b) {} (builtins.attrValues (builtins.intersectAttrs (builtins.listToAttrs (map (s: {
        name = s;
        value = null;
      })
      cfg.shares))
    allShares));
  };
}
