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
      ],

      "ssh": [
        {
          "action": "accept",
          "src":    ["autogroup:member"],
          "dst":    ["autogroup:self"],
          "users":  ["autogroup:nonroot", "root"],
        },
        {
          "action": "accept",
          "src":    ["autogroup:member"],
          "dst":    ["tag:cypher"],
          "users":  ["root", "autogroup:nonroot"],
        },
      ],

      "tagOwners": {
        "tag:k8s":    ["autogroup:admin"],
        "tag:cypher": ["autogroup:owner"],
      },
    }
  EOT
}
