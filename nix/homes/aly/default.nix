{
  pkgs,
  self,
  ...
}: {
  imports = [
    self.homeModules.default
  ];

  home = {
    homeDirectory = "/home/aly";
    stateVersion = "25.11";
    username = "aly";
  };

  programs = {
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
        // rootMe "pastoria"
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
}
