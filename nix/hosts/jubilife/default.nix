{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.jubilife = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {inherit inputs self;};
    modules = import ./configuration.nix {inherit inputs self;};
  };
}
