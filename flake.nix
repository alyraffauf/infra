{
  description = "cute.haus infra";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    files.url = "github:alyraffauf/flake-files";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:denful/import-tree";

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    blzrd = {
      url = "github:alyraffauf/blzrd";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Non-flake inputs
    absolute = {
      url = "github:ZeroQI/Absolute-Series-Scanner";
      flake = false;
    };

    audnexus = {
      url = "github:djdembeck/Audnexus.bundle";
      flake = false;
    };

    hama = {
      url = "github:ZeroQI/Hama.bundle";
      flake = false;
    };
  };

  nixConfig = {
    accept-flake-config = true;

    extra-substituters = [
      "https://cutehaus.cachix.org"
      "https://nix-community.cachix.org"
    ];

    extra-trusted-public-keys = [
      "cutehaus.cachix.org-1:KiifTsseQBitoaHH8rkDUDwzyz9akLeOM+K+e2eK8dA="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  outputs = inputs @ {
    flake-parts,
    nixpkgs,
    ...
  }: let
    sharedPackageSets = {
      aarch64-darwin = import nixpkgs {
        system = "aarch64-darwin";
      };

      x86_64-linux = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
        overlays = [inputs.self.overlays.default];
      };
    };
  in
    flake-parts.lib.mkFlake {
      inherit inputs;
      specialArgs = {inherit sharedPackageSets;};
    } {
      systems = builtins.attrNames sharedPackageSets;

      perSystem = {system, ...}: {
        _module.args.pkgs = sharedPackageSets.${system};
      };

      imports = [
        (inputs.import-tree ./nix/modules)
        inputs.files.flakeModules.default
        inputs.flake-parts.flakeModules.modules
        inputs.blzrd.flakeModule
        inputs.treefmt-nix.flakeModule
      ];
    };
}
