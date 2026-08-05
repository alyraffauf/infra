{
  config,
  lib,
  ...
}: {
  options.myDisko.profile.btrfsSubvolumes.enable = lib.mkEnableOption "the btrfs subvolume disk layout";

  config = lib.mkIf config.myDisko.profile.btrfsSubvolumes.enable {
    assertions = [
      {
        assertion = config.myDisko.installDrive != "";
        message = "config.myDisko.installDrive cannot be empty.";
      }
    ];

    disko.devices = {
      disk = {
        main = {
          type = "disk";
          device = config.myDisko.installDrive;

          content = {
            type = "gpt";

            partitions = {
              ESP = {
                content = {
                  format = "vfat";
                  mountOptions = ["umask=0077"];
                  mountpoint = "/boot";
                  type = "filesystem";
                };

                end = "1024M";
                name = "ESP";
                priority = 1;
                start = "1M";
                type = "EF00";
              };

              root = {
                size = "100%";
                content = {
                  type = "btrfs";
                  extraArgs = ["-f"];

                  subvolumes = {
                    "/rootfs" = {
                      mountOptions = ["compress=zstd" "noatime"];
                      mountpoint = "/";
                    };

                    "/home" = {
                      mountOptions = ["compress=zstd" "noatime"];
                      mountpoint = "/home";
                    };

                    "/home/.snapshots" = {
                      mountOptions = ["compress=zstd" "noatime"];
                      mountpoint = "/home/.snapshots";
                    };

                    "/nix" = {
                      mountOptions = ["compress=zstd" "noatime"];
                      mountpoint = "/nix";
                    };
                  };

                  mountpoint = "/partition-root";
                };
              };
            };
          };
        };
      };
    };
  };
}
