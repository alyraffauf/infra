{
  flake.modules.nixos.base = {
    programs = {
      direnv = {
        enable = true;
        nix-direnv.enable = true;
        silent = true;
      };

      fish.enable = true;
      git.enable = true;
      htop.enable = true;
      nh.enable = true;
    };
  };
}
