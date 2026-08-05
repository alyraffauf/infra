{lib, ...}: {
  options.myNixOs.profile.arr = {
    enable = lib.mkEnableOption "*arr services";

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib";
      description = "The directory where *arr stores its data files.";
    };
  };
}
