{lib, ...}: {
  options.myDisko.installDrive = lib.mkOption {
    description = "Disk to install NixOS to.";
    default = "/dev/sda";
    type = lib.types.str;
  };
}
