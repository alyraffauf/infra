_: {
  flake.nixosModules.default = {
    security.sudo-rs.enable = true;
  };
}
