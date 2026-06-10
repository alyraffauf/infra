_: {
  flake.diskoConfigurations = {
    btrfs-subvolumes = {
      config,
      lib,
      ...
    }: {
      options.myDisko.installDrive = lib.mkOption {
        description = "Disk to install NixOS to.";
        default = "/dev/nvme0n1";
        type = lib.types.str;
      };

      config = {
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
    };

    luks-btrfs-subvolumes = {
      config,
      lib,
      ...
    }: {
      options.myDisko.installDrive = lib.mkOption {
        description = "Disk to install NixOS to.";
        default = "/dev/nvme0n1";
        type = lib.types.str;
      };

      config = {
        assertions = [
          {
            assertion = config.myDisko.installDrive != "";
            message = "config.myDisko.installDrive cannot be empty.";
          }
        ];

        disko.devices = {
          disk = {
            vdb = {
              type = "disk";
              device = config.myDisko.installDrive;

              content = {
                type = "gpt";

                partitions = {
                  ESP = {
                    content = {
                      format = "vfat";

                      mountOptions = [
                        "defaults"
                        "umask=0077"
                      ];

                      mountpoint = "/boot";
                      type = "filesystem";
                    };

                    size = "1024M";
                    type = "EF00";
                  };

                  luks = {
                    size = "100%";
                    content = {
                      type = "luks";
                      name = "crypted";

                      content = {
                        type = "btrfs";
                        extraArgs = ["-f"];

                        subvolumes = {
                          "/home" = {
                            mountpoint = "/home";
                            mountOptions = ["compress=zstd" "noatime"];
                          };

                          "/home/.snapshots" = {
                            mountOptions = ["compress=zstd" "noatime"];
                            mountpoint = "/home/.snapshots";
                          };

                          "/nix" = {
                            mountpoint = "/nix";
                            mountOptions = ["compress=zstd" "noatime"];
                          };

                          "persist" = {
                            mountpoint = "/persist";
                            mountOptions = ["compress=zstd" "noatime"];
                          };

                          "/root" = {
                            mountpoint = "/";
                            mountOptions = ["compress=zstd" "noatime"];
                          };
                        };
                      };

                      settings = {
                        allowDiscards = true;
                        bypassWorkqueues = true;
                        crypttabExtraOpts = ["fido2-device=auto" "token-timeout=20"];
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
    };

    lvm-ext4 = {
      config,
      lib,
      ...
    }: {
      options.myDisko.installDrive = lib.mkOption {
        description = "Disk to install NixOS to.";
        default = "/dev/sda";
        type = lib.types.str;
      };

      config = {
        assertions = [
          {
            assertion = config.myDisko.installDrive != "";
            message = "config.myDisko.installDrive cannot be empty.";
          }
        ];

        disko.devices = {
          disk.disk1 = {
            device = config.myDisko.installDrive;
            type = "disk";
            content = {
              type = "gpt";
              partitions = {
                boot = {
                  name = "boot";
                  size = "1M";
                  type = "EF02";
                };
                esp = {
                  name = "ESP";
                  size = "500M";
                  type = "EF00";
                  content = {
                    type = "filesystem";
                    format = "vfat";
                    mountpoint = "/boot";
                  };
                };
                root = {
                  name = "root";
                  size = "100%";
                  content = {
                    type = "lvm_pv";
                    vg = "pool";
                  };
                };
              };
            };
          };

          lvm_vg = {
            pool = {
              type = "lvm_vg";
              lvs = {
                root = {
                  size = "100%FREE";
                  content = {
                    type = "filesystem";
                    format = "ext4";
                    mountpoint = "/";
                    mountOptions = [
                      "defaults"
                    ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
