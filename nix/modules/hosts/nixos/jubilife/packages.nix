_: {
  flake.nixosModules.jubilife = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      abcde
      age
      chezmoi
      claude-code
      codex
      curl
      delta
      eza
      ffmpeg-full
      flac
      fzf
      gh
      handbrake
      lazygit
      mediainfo
      mkvtoolnix
      opencode
      rclone
      restic
      ripgrep
      starship
      zoxide
    ];
  };
}
