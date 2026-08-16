_: {
  flake.nixosModules.swap = {
    config,
    lib,
    ...
  }: {
    options.myNixOs.profile.swap = {
      size = lib.mkOption {
        default = 8192;
        description = "Swap size in megabytes.";
        type = lib.types.int;
      };
    };

    config = {
      swapDevices = [
        {
          device = "/.swap";
          priority = 0;
          randomEncryption.enable = true;
          inherit (config.myNixOs.profile.swap) size;
        }
      ];
    };
  };
}
