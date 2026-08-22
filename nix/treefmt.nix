_: {
  perSystem = _: {
    treefmt.config = {
      programs = {
        alejandra.enable = true;
        prettier.enable = true;
        shellcheck.enable = true;
        shfmt.enable = true;
        terraform.enable = true;
      };

      settings.excludes = ["secrets/**"];
    };
  };
}
