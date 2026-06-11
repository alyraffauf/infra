{self, ...}: {
  flake.modules.nixos.base = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.myFlakeUrl = lib.mkOption {
      type = lib.types.str;
      default = "github:alyraffauf/cute.haus";
      description = "Default flake URL for this NixOS configuration.";
    };

    config = {
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

      hardware.enableAllFirmware = true;
      networking.networkmanager.enable = true;
      security.sudo-rs.enable = true;

      programs = {
        direnv = {
          enable = true;
          nix-direnv.enable = true;
          silent = true;
        };

        fish.enable = true;
        git.enable = true;
        htop.enable = true;
        nh.enable = true;
      };

      services = {
        fstrim.enable = true;

        openssh = {
          enable = true;
          openFirewall = true;
          settings.PasswordAuthentication = false;
        };

        timesyncd.enable = true;
      };

      sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

      system = {
        autoUpgrade = {
          enable = true;
          allowReboot = true;
          flags = ["--accept-flake-config"];
          flake = config.myFlakeUrl;
          operation = lib.mkDefault "switch";
          dates = lib.mkDefault "02:00";
          randomizedDelaySec = lib.mkDefault "0";
          persistent = true;

          rebootWindow = {
            lower = "02:00";
            upper = "06:00";
          };
        };

        configurationRevision = self.rev or self.dirtyRev or null;
      };

      systemd = {
        coredump.enable = false;
        enableEmergencyMode = false;
      };
    };
  };
}
