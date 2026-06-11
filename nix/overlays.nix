{
  flake.overlays = {
    default = _final: prev: {
      qbittorrent-nox = prev.qbittorrent-nox.overrideAttrs (_old: rec {
        version = "5.2.1";

        src = prev.fetchFromGitHub {
          owner = "qbittorrent";
          repo = "qBittorrent";
          rev = "release-${version}";
          hash = "sha256-xC0XCVbshs4rtfLoJKKp0+IeSN2SRg7J5G504TcXFPI=";
        };
      });
    };
  };
}
