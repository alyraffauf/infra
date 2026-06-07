locals {
  aly_codes_ingress_hosts = toset([
    "aly.codes",
    "git.aly.codes",
    "status.aly.codes",
    "vibes.aly.codes",
  ])
  aly_codes_fm_dkim = toset(["fm1", "fm2", "fm3"])
}

resource "cloudflare_dns_record" "aly_codes_a" {
  for_each = local.aly_codes_ingress_hosts
  zone_id  = local.zones.aly_codes
  name     = each.value
  type     = "A"
  content  = local.hosts.snowpoint
  proxied  = true
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "aly_codes_ssh_a" {
  zone_id  = local.zones.aly_codes
  name     = "ssh.aly.codes"
  type     = "A"
  content  = local.hosts.snowpoint
  proxied  = false
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "aly_codes_fm_dkim_cname" {
  for_each = local.aly_codes_fm_dkim
  zone_id  = local.zones.aly_codes
  name     = "${each.value}._domainkey.aly.codes"
  type     = "CNAME"
  content  = "${each.value}.aly.codes.dkim.fmhosted.com"
  proxied  = false
  ttl      = 1
  tags     = []
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "aly_codes_switchyard_cname" {
  zone_id = local.zones.aly_codes
  name    = "switchyard.aly.codes"
  type    = "CNAME"
  content = "alyraffauf.github.io"
  proxied = false
  ttl     = 1
  tags    = []
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "aly_codes_www_cname" {
  zone_id = local.zones.aly_codes
  name    = "www.aly.codes"
  type    = "CNAME"
  content = "aly.codes"
  proxied = true
  ttl     = 1
  tags    = []
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "aly_codes_apex_mx_10" {
  zone_id  = local.zones.aly_codes
  name     = "aly.codes"
  type     = "MX"
  content  = "in1-smtp.messagingengine.com"
  priority = 10
  proxied  = false
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "aly_codes_apex_mx_20" {
  zone_id  = local.zones.aly_codes
  name     = "aly.codes"
  type     = "MX"
  content  = "in2-smtp.messagingengine.com"
  priority = 20
  proxied  = false
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "aly_codes_apex_google_verify_txt" {
  zone_id  = local.zones.aly_codes
  name     = "aly.codes"
  type     = "TXT"
  content  = "\"google-site-verification=_mw84PWITYHkgikw4hTBScr1lWnQzh761cnrb6Uviyo\""
  proxied  = false
  ttl      = 3600
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "aly_codes_apex_spf_txt" {
  zone_id  = local.zones.aly_codes
  name     = "aly.codes"
  type     = "TXT"
  content  = "\"v=spf1 include:spf.messagingengine.com ?all\""
  proxied  = false
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "aly_codes_atproto_txt" {
  zone_id  = local.zones.aly_codes
  name     = "_atproto.aly.codes"
  type     = "TXT"
  content  = "\"did=did:plc:zntngpowgd6rorjt3haywj36\""
  proxied  = false
  ttl      = 1
  tags     = []
  settings = {}
}
