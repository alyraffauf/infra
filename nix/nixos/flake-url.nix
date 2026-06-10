_: {
  flake.modules.nixos.flake-url = {lib, ...}: {
    options.myFlakeUrl = lib.mkOption {
      type = lib.types.str;
      default = "github:alyraffauf/cute.haus";
      description = "Default flake URL for this NixOS configuration.";
    };
  };
}
