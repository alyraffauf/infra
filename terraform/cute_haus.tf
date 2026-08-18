locals {
  cute_haus_ingress = {
    "auth-navidrome.cute.haus" = true
    "collabora.cute.haus"      = false
    "cute.haus"                = true
    "immich.cute.haus"         = false
    "kuma.cute.haus"           = true
    "navidrome.cute.haus"      = true
    "nextcloud.cute.haus"      = false
    "paperless.cute.haus"      = false
    "photoprism.cute.haus"     = false
    "seerr.cute.haus"          = true
    "slingshot.cute.haus"      = true
  }

  cute_haus_johto_ingress = toset([
    "collabora.cute.haus",
    "immich.cute.haus",
    "nextcloud.cute.haus",
    "paperless.cute.haus",
    "kuma.cute.haus",
  ])
}

moved {
  from = cloudflare_dns_record.cute_haus_a["id.cute.haus"]
  to   = cloudflare_dns_record.cute_haus_id
}

moved {
  from = cloudflare_dns_record.cute_haus_a["vault.cute.haus"]
  to   = cloudflare_dns_record.cute_haus_vault
}

moved {
  from = cloudflare_dns_record.cute_haus_a["pds.cute.haus"]
  to   = cloudflare_dns_record.cute_haus_pds
}

moved {
  from = cloudflare_dns_record.cute_haus_a["ombi.cute.haus"]
  to   = cloudflare_dns_record.cute_haus_ombi
}

moved {
  from = cloudflare_dns_record.cute_haus_a["plex.cute.haus"]
  to   = cloudflare_dns_record.cute_haus_plex
}

resource "cloudflare_dns_record" "cute_haus_a" {
  for_each = local.cute_haus_ingress
  zone_id  = local.zones.cute_haus
  name     = each.key
  type     = "A"
  content  = contains(local.cute_haus_johto_ingress, each.key) ? local.hosts.olivine : local.hosts.pastoria
  proxied  = each.value
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "cute_haus_id" {
  zone_id  = local.zones.cute_haus
  name     = "id.cute.haus"
  type     = "A"
  content  = local.hosts.sunnyshore
  proxied  = true
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "cute_haus_vault" {
  zone_id  = local.zones.cute_haus
  name     = "vault.cute.haus"
  type     = "A"
  content  = local.hosts.sunnyshore
  proxied  = true
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "cute_haus_pds" {
  zone_id  = local.zones.cute_haus
  name     = "pds.cute.haus"
  type     = "A"
  content  = local.hosts.sunnyshore
  proxied  = false
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "cute_haus_ombi" {
  zone_id  = local.zones.cute_haus
  name     = "ombi.cute.haus"
  type     = "A"
  content  = local.hosts.sunnyshore
  proxied  = true
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "cute_haus_plex" {
  zone_id  = local.zones.cute_haus
  name     = "plex.cute.haus"
  type     = "A"
  content  = local.hosts.olivine
  proxied  = false
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "cute_haus_www_cname" {
  zone_id = local.zones.cute_haus
  name    = "www.cute.haus"
  type    = "CNAME"
  content = "cute.haus"
  proxied = false
  ttl     = 1
  tags    = []
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "cute_haus_atproto_txt" {
  zone_id  = local.zones.cute_haus
  name     = "_atproto.cute.haus"
  type     = "TXT"
  content  = "\"did=did:plc:rkos3laovknh53dwtdguu27n\""
  proxied  = false
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "cute_haus_apex_google_verify_txt" {
  zone_id  = local.zones.cute_haus
  name     = "cute.haus"
  type     = "TXT"
  content  = "\"google-site-verification=jN1nPjBAhwmZKG9jNUV631cEC_k7rZhlQxncMablr-E\""
  proxied  = false
  ttl      = 3600
  tags     = []
  settings = {}
}
