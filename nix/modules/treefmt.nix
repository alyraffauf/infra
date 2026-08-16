{
  perSystem.treefmt.config = {
    settings.global.excludes = [
      # `sops-rekey` generates this file and rewrites encrypted recipient
      # metadata in both secret locations. Formatting ciphertext would create
      # a noisy, invalid rekey diff.
      ".sops.yaml"
      "secrets/*.yaml"
      "k8s/flux/secrets/*.sops.yaml"
      # Draft Helm templates are intentionally retained without being rendered
      # or validated as Kubernetes YAML.
      "k8s/drafts/**"
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
