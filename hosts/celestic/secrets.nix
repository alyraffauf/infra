{self, ...}: {
  age.secrets = {
    cloudflare.file = "${self.inputs.secrets}/cloudflare.age";
    k3s.file = "${self.inputs.secrets}/k3s.age";
    rclone-b2.file = "${self.inputs.secrets}/rclone/b2.age";
    restic-passwd.file = "${self.inputs.secrets}/restic-password.age";
    tailscaleAuthKey.file = "${self.inputs.secrets}/tailscale/auth.age";
  };
}
