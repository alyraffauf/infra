_: {
  flake.modules.nixos.swap = {
    config,
    lib,
    ...
  }: {
    options.mySwap.size = lib.mkOption {
      default = 8192;
      description = "Swap size in megabytes.";
      type = lib.types.int;
    };

    config = {
      swapDevices = [
        {
          device = "/.swap";
          priority = 0;
          randomEncryption.enable = true;
          inherit (config.mySwap) size;
        }
      ];
    };
  };
}
