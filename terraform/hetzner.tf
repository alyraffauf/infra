resource "hcloud_server" "celestic" {
  name         = "celestic"
  server_type  = "cx22"
  image        = "ubuntu-24.04"
  location     = "nbg1"
  backups      = true
  firewall_ids = []
}

resource "hcloud_server" "solaceon" {
  name         = "solaceon"
  server_type  = "cx22"
  image        = "ubuntu-24.04"
  location     = "nbg1"
  backups      = true
  firewall_ids = [2127864]
}
