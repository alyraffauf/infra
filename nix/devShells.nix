{
  perSystem = {
    lib,
    pkgs,
    inputs',
    self',
    ...
  }: let
    # `kubernetes.core` ansible collection needs the kubernetes python lib.
    ansibleWithK8s = pkgs.python3.withPackages (ps:
      with ps; [
        ansible
        ansible-core
        kubernetes
      ]);

    helmWithDiff = pkgs.wrapHelm pkgs.kubernetes-helm {
      plugins = [pkgs.kubernetes-helmPlugins.helm-diff];
    };
  in {
    devShells.default = pkgs.mkShell {
      packages =
        (with pkgs; [
          age
          ansibleWithK8s
          bun
          fluxcd
          git
          helmfile
          just
          kustomize
          kubectl
          helmWithDiff
          nh
          skopeo
          sops
          ssh-to-age
          opentofu
          vals
        ])
        # ++ lib.attrValues config.treefmt.build.programs
        ++ [
          inputs'.nynx.packages.nynx
          self'.packages.gen-files
        ]
        ++ lib.optionals pkgs.stdenv.isLinux [
          inputs'.disko.packages.disko-install
        ];

      shellHook = ''
        echo "Generating files..."
        ${lib.getExe self'.packages.gen-files}
        export FLAKE="." NH_FLAKE="."
        echo "👋 Welcome to the cute.haus devShell!"
      '';
    };
  };
}
