# Tailscale tailnet ACL policy for narwhal-snapper.ts.net.
# Edit the `acl` field below and `tofu apply` to push changes.
# Run `tofu plan` first to preview the diff.

resource "tailscale_acl" "tailnet" {
  acl = <<-EOT
    {
      "acls": [
        {
          "action": "accept",
          "src":    ["*"],
          "dst":    ["*:*"],
        },
      ],

      "nodeAttrs": [
        {
          "attr":   ["mullvad"],
          "target": ["100.106.251.41"],
        },
        {
          "attr":   ["mullvad"],
          "target": ["100.76.68.70"],
        },
        {
          "attr":   ["mullvad"],
          "target": ["100.124.238.118"],
        },
        {
          "attr":   ["mullvad"],
          "target": ["100.115.185.117"],
        },
        {
          "attr":   ["mullvad"],
          "target": ["100.64.222.8"],
        },
        {
          "attr":   ["mullvad"],
          "target": ["100.87.104.118"],
        },
        {
          "attr":   ["mullvad"],
          "target": ["100.100.102.26"],
        },
        {
          "attr":   ["funnel"],
          "target": ["tag:safari-ingress"],
        },
      ],

      "ssh": [
        {
          "src":    ["autogroup:member", "aly@passkey"],
          "dst":    ["autogroup:self", "autogroup:tagged"],
          "users":  ["autogroup:nonroot", "root"],
          "action": "accept",
        },
      ],

      "tagOwners": {
        "tag:k8s":            ["autogroup:admin"],
        "tag:hermes":         ["autogroup:admin"],
        "tag:safari-ingress": ["autogroup:admin"],
        "tag:safari-service": ["autogroup:admin"],
      },

      "autoApprovers": {
        "services": {
          "tag:safari-service": ["tag:safari-ingress"],
        },
      },

      "grants": [
        {
          "src": ["*"],
          "dst": ["tag:safari-service"],
          "ip":  ["443"],
        },
      ],
    }
  EOT
}
