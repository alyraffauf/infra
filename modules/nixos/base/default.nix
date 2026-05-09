{
  config,
  lib,
  pkgs,
  self,
  ...
}: {
  options.myNixOS.base.enable = lib.mkEnableOption "base system configuration";

  config = lib.mkIf config.myNixOS.base.enable {
    environment = {
      etc."nixos".source = self;

      systemPackages = with pkgs; [
        (inxi.override {withRecommends = true;})
        helix
        lm_sensors
        python314 # For ansible
        rclone
        wget
        zellij
      ];

      variables = {
        inherit (config.myNixOS) FLAKE;
        NH_FLAKE = config.myNixOS.FLAKE;
      };
    };

    programs = {
      dconf.enable = true; # Needed for home-manager

      direnv = {
        enable = true;
        nix-direnv.enable = true;
        silent = true;
      };

      git.enable = true;
      htop.enable = true;
      nh.enable = true;
      ssh.knownHosts = config.mySnippets.ssh.knownHosts;
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

    # Decrypt sops secrets using the host's ssh ed25519 host key (converted
    # to age at decrypt time). Each host's pubkey lives in publicKeys/
    # and is listed in .sops.yaml; per-secret declarations live in each
    # host's secrets.nix.
    sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

    system.configurationRevision = self.rev or self.dirtyRev or null;

    systemd = {
      # Attempt to limp to accessible state on failure.
      coredump.enable = false;
      enableEmergencyMode = false;
    };

    myNixOS = {
      profiles.performance.enable = true;
      programs.njust.enable = true;
      services.fail2ban.enable = true;
    };
  };
}
