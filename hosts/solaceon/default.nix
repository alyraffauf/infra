{
  config,
  modulesPath,
  pkgs,
  self,
  ...
}: {
  imports = [
    ./secrets.nix
    ./services.nix
    "${modulesPath}/profiles/qemu-guest.nix"
    self.diskoConfigurations.lvm-ext4
    self.nixosModules.locale-en-us
  ];

  boot = {
    initrd.availableKernelModules = [
      "ahci"
      "sd_mod"
      "sr_mod"
      "virtio_pci"
      "virtio_scsi"
      "xhci_pci"
    ];

    loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };

  networking = {
    firewall.allowedTCPPorts = [2222 8282 8383];
    hostName = "solaceon";
  };

  services.k3s = {
    enable = true;
    role = "server";
    clusterInit = true;
    tokenFile = config.age.secrets.k3s.path;
    extraFlags = [
      "--write-kubeconfig-mode=644"
      "--service-node-port-range=8000-32767"
      "--flannel-iface=tailscale0"
      "--tls-san=celestic"
      "--disable=traefik"
      "--disable=servicelb"
    ];

    autoDeployCharts.aly-codes = {
      package = pkgs.runCommand "aly-codes-chart.tgz" {nativeBuildInputs = [pkgs.kubernetes-helm];} ''
        cp -r ${../../charts/aly-codes} ./chart
        chmod -R +w ./chart
        helm package ./chart --destination .
        mv ./*.tgz $out
      '';
      targetNamespace = "default";
    };

    autoDeployCharts.watsup = {
      package = pkgs.runCommand "watsup-chart.tgz" {nativeBuildInputs = [pkgs.kubernetes-helm];} ''
        cp -r ${../../charts/watsup} ./chart
        chmod -R +w ./chart
        helm package ./chart --destination .
        mv ./*.tgz $out
      '';
      targetNamespace = "default";
    };
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  programs.ssh.knownHosts = config.mySnippets.ssh.knownHosts;
  system.stateVersion = "25.11";
  time.timeZone = "America/New_York";
  myDisko.installDrive = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_62292463";

  myNixOS = {
    base.enable = true;

    profiles = {
      autoUpgrade.enable = true;
      backups.enable = true;
      vps.enable = true;

      swap = {
        enable = true;
        size = 2048;
      };

      zram.enable = true;
    };

    programs = {
      nix.enable = true;
      podman.enable = true;
    };

    services = {
      forgejo = {
        enable = true;
        db = "postgresql";
      };

      prometheusNode.enable = true;
      promtail.enable = true;
      tailscale.enable = true;
    };
  };

  myUsers.root.enable = true;
}
