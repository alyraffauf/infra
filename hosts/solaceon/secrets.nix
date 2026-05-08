{self, ...}: {
  age.secrets = {
    aly-codes-tls-crt.file = "${self.inputs.secrets}/aly-codes-tls.crt.age";
    aly-codes-tls-key.file = "${self.inputs.secrets}/aly-codes-tls.key.age";
    aly-social-tls-crt.file = "${self.inputs.secrets}/aly-social-tls.crt.age";
    aly-social-tls-key.file = "${self.inputs.secrets}/aly-social-tls.key.age";
    cute-haus-tls-crt.file = "${self.inputs.secrets}/cute-haus-tls.crt.age";
    cute-haus-tls-key.file = "${self.inputs.secrets}/cute-haus-tls.key.age";
    morsels-blue-tls-crt.file = "${self.inputs.secrets}/morsels-blue-tls.crt.age";
    morsels-blue-tls-key.file = "${self.inputs.secrets}/morsels-blue-tls.key.age";
    k3s.file = "${self.inputs.secrets}/k3s.age";
    pds.file = "${self.inputs.secrets}/pds.age";
    rclone-b2.file = "${self.inputs.secrets}/rclone/b2.age";
    restic-passwd.file = "${self.inputs.secrets}/restic-password.age";
    tailscaleAuthKey.file = "${self.inputs.secrets}/tailscale/auth.age";
  };
}
