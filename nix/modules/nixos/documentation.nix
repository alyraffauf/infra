_: {
  flake.nixosModules.default = {
    documentation = {
      enable = false;
      nixos.enable = false;
    };
  };
}
