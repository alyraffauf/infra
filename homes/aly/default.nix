{
  config,
  lib,
  pkgs,
  self,
  ...
}: {
  imports = [
    self.homeModules.default
    self.inputs.sops-nix.homeManagerModules.sops
    self.inputs.safari.homeModules.default
  ];

  sops = {
    age.sshKeyPaths = ["${config.home.homeDirectory}/.ssh/id_ed25519"];

    secrets = {
      aws = {
        sopsFile = ../../secrets/aly.yaml;
        key = "aws";
      };
      rclone-b2 = {
        sopsFile = ../../secrets/b2.yaml;
        key = "rclone_config";
      };
    };
  };

  home = {
    homeDirectory = "/home/aly";

    packages = with pkgs; [
      curl
      rclone
      restic
    ];

    stateVersion = "25.11";
    username = "aly";
  };

  programs = {
    awscli = {
      enable = true;

      credentials = {
        "default" = {
          "credential_process" = ''sh -c "${lib.getExe' pkgs.uutils-coreutils-noprefix "cat"} ${config.sops.secrets.aws.path}"'';
        };
      };
    };

    delta = {
      enable = true;
      enableGitIntegration = true;
    };

    git = {
      enable = true;
      lfs.enable = true;

      settings = {
        color.ui = true;
        github.user = "alyraffauf";
        push.autoSetupRemote = true;

        user = {
          name = "Aly Raffauf";
          email = "aly@aly.codes";
        };
      };
    };

    helix.defaultEditor = true;
    lazygit.enable = true;

    ssh = {
      enable = true;
      enableDefaultConfig = false;

      matchBlocks = let
        rootMe = name: {
          ${name} = {
            hostname = name;
            user = "root";
          };
        };
      in
        rootMe "snowpoint"
        // rootMe "celestic"
        // rootMe "solaceon"
        // {
          "*" = {
            forwardAgent = false;
            addKeysToAgent = "no";
            compression = false;
            serverAliveInterval = 0;
            serverAliveCountMax = 3;
            hashKnownHosts = false;
            userKnownHostsFile = "~/.ssh/known_hosts";
            controlMaster = "no";
            controlPath = "~/.ssh/master-%r@%n:%p";
            controlPersist = "no";
          };
        };

      package = pkgs.openssh;
    };
  };

  safari = {
    enable = true;
    fish.enable = true;
  };
}
