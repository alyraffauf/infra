{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.eterna = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {inherit inputs self;};
    modules = import ./configuration.nix {inherit inputs self;};
  };
}
