{self, ...}: {
  flake.modules.nixos.base = {
    config,
    pkgs,
    ...
  }: {
    environment = {
      etc."nixos".source = self;

      systemPackages = with pkgs; [
        (inxi.override {withRecommends = true;})
        helix
        lm_sensors
        python314
        rclone
        wget
        zellij
      ];

      variables = {
        FLAKE = config.myFlakeUrl;
        NH_FLAKE = config.myFlakeUrl;
      };
    };

    programs = {
      direnv = {
        enable = true;
        nix-direnv.enable = true;
        silent = true;
      };

      git.enable = true;
      htop.enable = true;
      nh.enable = true;
    };

    networking.networkmanager.enable = true;
    security.sudo-rs.enable = true;

    services = {
      openssh = {
        enable = true;
        openFirewall = true;
        settings.PasswordAuthentication = false;
      };

      timesyncd.enable = true;
    };

    sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

    system.configurationRevision = self.rev or self.dirtyRev or null;

    systemd = {
      coredump.enable = false;
      enableEmergencyMode = false;
    };
  };
}
