_: {
  flake.modules.nixos.recipes = {lib, ...}: {
    options.myRecipes = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
    };
  };
}
