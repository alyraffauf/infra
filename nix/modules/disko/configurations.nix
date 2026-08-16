{self, ...}: {
  flake.diskoConfigurations = {
    btrfs-subvolumes = {
      imports = [
        self.nixosModules.disko
        self.nixosModules.btrfsSubvolumes
      ];
      myDisko.installDrive = "/dev/nvme0n1";
    };

    luks-btrfs-subvolumes = {
      imports = [
        self.nixosModules.disko
        self.nixosModules.luksBtrfsSubvolumes
      ];
      myDisko.installDrive = "/dev/nvme0n1";
    };

    lvm-ext4 = {
      imports = [
        self.nixosModules.disko
        self.nixosModules.lvmExt4
      ];
    };
  };
}
