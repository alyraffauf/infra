{
  description = "Aly's NixOS homelab flake with flake-parts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    actions-nix = {
      url = "github:alyraffauf/actions.nix";

      inputs = {
        git-hooks.follows = "git-hooks-nix";
        nixpkgs.follows = "nixpkgs";
      };
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    files.url = "github:alyraffauf/flake-files";
    flake-parts.url = "github:hercules-ci/flake-parts";

    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nynx = {
      url = "github:alyraffauf/nynx";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    safari = {
      url = "github:alyraffauf/safari";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    snippets = {
      url = "github:alyraffauf/snippets";
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

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["aarch64-darwin" "x86_64-linux"];

      imports = [
        ./nix/modules/flake
        inputs.actions-nix.flakeModules.default
        inputs.files.flakeModules.default
        inputs.git-hooks-nix.flakeModule
        inputs.home-manager.flakeModules.home-manager
        inputs.treefmt-nix.flakeModule
      ];
    };
}
