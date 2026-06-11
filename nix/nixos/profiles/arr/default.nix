{
  flake.modules.nixos.arr = {lib, ...}: {
    options.myArr.dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib";
      description = "The directory where *arr stores its data files.";
    };
  };
}
