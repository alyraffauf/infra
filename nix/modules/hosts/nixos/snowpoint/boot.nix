_: {
  flake.nixosModules.snowpoint = {
    boot.loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };
}
