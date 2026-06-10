{
  config,
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.twinleaf = inputs.nixpkgs.lib.nixosSystem {
    modules = with config.flake.modules.nixos; [
      iso
      nix-config
      njust
      recipes

      inputs.sops-nix.nixosModules.sops
      (
        {
          lib,
          modulesPath,
          ...
        }: {
          imports = [
            "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
          ];

          image.baseName = lib.mkForce "twinleaf";
          networking.hostName = "twinleaf";
          nixpkgs.hostPlatform = "x86_64-linux";
        }
      )

      {
        nixpkgs = {
          overlays = [self.overlays.default];
          config.allowUnfree = true;
        };
      }
    ];
  };
}
