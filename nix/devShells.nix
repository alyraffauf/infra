_: {
  perSystem = {pkgs, ...}: {
    devShells.default = pkgs.mkShell {
      packages = [
        pkgs.age
        pkgs.git
        pkgs.jq
        pkgs.just
        pkgs.opentofu
        pkgs.sops
        pkgs.ssh-to-age
        pkgs.yq-go
      ];

      shellHook = ''
        export FLAKE="." NH_FLAKE="."
        echo "Welcome to the infra devShell."
      '';
    };
  };
}
