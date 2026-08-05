{inputs, ...}: let
  myDisko = inputs.import-tree ./disko;
in {
  flake.diskoConfigurations = {
    btrfs-subvolumes = {
      imports = [myDisko];
      myDisko.installDrive = "/dev/nvme0n1";
      myDisko.profile.btrfsSubvolumes.enable = true;
    };

    luks-btrfs-subvolumes = {
      imports = [myDisko];
      myDisko.installDrive = "/dev/nvme0n1";
      myDisko.profile.luksBtrfsSubvolumes.enable = true;
    };

    lvm-ext4 = {
      imports = [myDisko];
      myDisko.profile.lvmExt4.enable = true;
    };
  };

  flake.nixosModules.myDisko = myDisko;
}
