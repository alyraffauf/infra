{
  self,
  inputs,
  ...
}: {
  flake = {
    diskoConfigurations = {
      btrfs-subvolumes = ../disko/btrfs-subvolumes;
      luks-btrfs-subvolumes = ../disko/luks-btrfs-subvolumes;
      lvm-ext4 = ../disko/lvm-ext4;
    };

    nixosModules = {
      hardware = inputs.import-tree ../hardware;
      locale-en-us = ../locale/en-us;
      nixos = inputs.import-tree ../nixos;
      users = inputs.import-tree ../users;
    };

    nixosConfigurations = let
      modules = self.nixosModules;
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
              (inputs.import-tree ../../hosts/${host})
              inputs.disko.nixosModules.disko
              inputs.lanzaboote.nixosModules.lanzaboote
              inputs.snippets.nixosModules.snippets
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
