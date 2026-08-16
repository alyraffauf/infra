{
  flake.overlays = {
    default = _final: prev: {
      qbittorrent-nox = prev.qbittorrent-nox.overrideAttrs (_old: rec {
        version = "5.2.2";

        src = prev.fetchFromGitHub {
          owner = "qbittorrent";
          repo = "qBittorrent";
          rev = "release-${version}";
          hash = "sha256-5lGv1ajuDE/DTqUbnVeRRBcXntrzn6bs72mZbQMf7Fc=";
        };
      });
    };
  };
}
