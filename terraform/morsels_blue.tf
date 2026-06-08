resource "cloudflare_dns_record" "morsels_blue_apex_a" {
  zone_id  = local.zones.morsels_blue
  name     = "morsels.blue"
  type     = "A"
  content  = local.hosts.pastoria
  proxied  = true
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "morsels_blue_www_cname" {
  zone_id = local.zones.morsels_blue
  name    = "www.morsels.blue"
  type    = "CNAME"
  content = "morsels.blue"
  proxied = true
  ttl     = 1
  tags    = []
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "morsels_blue_atproto_txt" {
  zone_id  = local.zones.morsels_blue
  name     = "_atproto.morsels.blue"
  type     = "TXT"
  content  = "\"did=did:plc:5hcxt353s5by5orpkbzs73so\""
  proxied  = false
  ttl      = 1
  tags     = []
  settings = {}
}
