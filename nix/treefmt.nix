{
  perSystem.treefmt.config = {
    settings.global.excludes = [
      "k8s/flux/secrets/*.sops.yaml"
      # Flux-generated upstream manifest (flux install output); Renovate bumps
      # it verbatim, so don't let prettier reformat/diverge it from upstream.
      "k8s/flux/system/gotk-components.yaml"
    ];

    programs = {
      alejandra.enable = true;
      deadnix.enable = true;
      prettier.enable = true;
      shellcheck.enable = true;
      shfmt.enable = true;
      statix.enable = true;
      taplo.enable = true;
      terraform.enable = true;
    };
  };
}
