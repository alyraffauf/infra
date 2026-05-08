resource "cloudflare_dns_record" "morsels_blue_apex_a_solaceon" {
  zone_id  = local.zones.morsels_blue
  name     = "morsels.blue"
  type     = "A"
  content  = local.hosts.solaceon
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

moved {
  from = cloudflare_dns_record.terraform_managed_resource_6401c9e7ed5fc63f7eeff153fc11e4ab_0
  to   = cloudflare_dns_record.morsels_blue_apex_a_solaceon
}

moved {
  from = cloudflare_dns_record.terraform_managed_resource_32bb70426f884ed0ab6eb1e3df15d363_2
  to   = cloudflare_dns_record.morsels_blue_www_cname
}

moved {
  from = cloudflare_dns_record.terraform_managed_resource_52079bb1c4710707da5651fcc9e08b84_3
  to   = cloudflare_dns_record.morsels_blue_atproto_txt
}
