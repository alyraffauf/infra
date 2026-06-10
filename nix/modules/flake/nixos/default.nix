{
  config,
  self,
  inputs,
  ...
}: {
  flake = {
    modules.nixos = {
      hardware = inputs.import-tree ../../hardware;
      nixos = inputs.import-tree ../../nixos;
    };

    nixosConfigurations = let
      modules = config.flake.modules.nixos;
    in
      inputs.nixpkgs.lib.genAttrs [
        "eterna"
        "jubilife"
        "pastoria"
        "snowpoint"
        "solaceon"
        "twinleaf"
      ] (
        host:
          inputs.nixpkgs.lib.nixosSystem {
            modules = [
              (inputs.import-tree ../../../hosts/${host})
              modules.locale-en-us
              modules.sshKeys
              inputs.disko.nixosModules.disko
              inputs.lanzaboote.nixosModules.lanzaboote
              inputs.sops-nix.nixosModules.sops
              modules.hardware
              modules.nixos
              modules.users

              {
                nixpkgs = {
                  overlays = [
                    self.overlays.default
                  ];

                  config.allowUnfree = true;
                };
              }
            ];

            specialArgs = {inherit self;};
          }
      );
  };
}
