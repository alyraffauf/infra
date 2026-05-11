locals {
  cute_haus_solaceon = {
    "audiobookshelf.cute.haus" = true
    "cute.haus"                = true
    "immich.cute.haus"         = true
    "jellyfin.cute.haus"       = false
    "kuma.cute.haus"           = true
    "ombi.cute.haus"           = true
    "pds.cute.haus"            = false
    "plex.cute.haus"           = false
    "status.cute.haus"         = true
    "vault.cute.haus"          = true
  }
}

resource "cloudflare_dns_record" "cute_haus_a_solaceon" {
  for_each = local.cute_haus_solaceon
  zone_id  = local.zones.cute_haus
  name     = each.key
  type     = "A"
  content  = local.hosts.solaceon
  proxied  = each.value
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "cute_haus_navidrome_a" {
  zone_id  = local.zones.cute_haus
  name     = "navidrome.cute.haus"
  type     = "A"
  content  = "107.140.155.124"
  proxied  = true
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
