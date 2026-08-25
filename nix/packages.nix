_: {
  perSystem = {pkgs, ...}: {
    packages.generate-host-readmes = pkgs.stdenv.mkDerivation {
      pname = "generate-host-readmes";
      version = "0.1.0";
      src = ../scripts;

      nativeBuildInputs = [pkgs.bun];

      # Fixup corrupts Bun's embedded application bundle.
      dontFixup = true;

      patchPhase = ''
        substituteInPlace generate-host-readmes.ts \
          --replace-fail 'const GIT_COMMAND = "git";' \
          'const GIT_COMMAND = "${pkgs.git}/bin/git";'
      '';

      buildPhase = ''
        bun build generate-host-readmes.ts --compile --outfile generate-host-readmes
      '';

      installPhase = ''
        install -Dm755 generate-host-readmes "$out/bin/generate-host-readmes"
      '';
    };
  };
}
