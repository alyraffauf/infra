_: {
  flake.modules.nixos.beelink-mini-s12pro = {
    boot.initrd.availableKernelModules = [
      "ahci"
      "sd_mod"
      "xhci_pci"
    ];
  };
}
