{
  flake.modules.nixos.base = {
    services.openssh = {
      enable = true;
      openFirewall = true;
      settings.PasswordAuthentication = false;
    };

    sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
  };
}
