{lib, ...}: {
  imports = [
    ./base
    ./profiles
    ./programs
    ./services
  ];

  options.myNixOS.FLAKE = lib.mkOption {
    type = lib.types.str;
    default = "github:alyraffauf/cute.haus";
    description = "Default flake URL for this NixOS configuration.";
  };
}
