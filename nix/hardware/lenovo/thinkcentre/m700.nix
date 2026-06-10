_: {
  flake.modules.nixos.lenovo-thinkcentre-m700 = {
    boot.initrd.availableKernelModules = [
      "ahci"
      "sd_mod"
      "xhci_pci"
    ];

    services.fwupd.enable = true;
  };
}
