{
  config,
  lib,
  ...
}: {
  options.myNixOs.profile.swap = {
    enable = lib.mkEnableOption "encrypted swap";

    size = lib.mkOption {
      default = 8192;
      description = "Swap size in megabytes.";
      type = lib.types.int;
    };
  };

  config = lib.mkIf config.myNixOs.profile.swap.enable {
    swapDevices = [
      {
        device = "/.swap";
        priority = 0;
        randomEncryption.enable = true;
        inherit (config.myNixOs.profile.swap) size;
      }
    ];
  };
}
