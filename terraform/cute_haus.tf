locals {
  cute_haus_ingress = {
    "audiobookshelf.cute.haus" = true
    "auth-navidrome.cute.haus" = true
    "collabora.cute.haus"      = false
    "cute.haus"                = true
    "id.cute.haus"             = true
    "immich.cute.haus"         = false
    "jellyfin.cute.haus"       = false
    "kuma.cute.haus"           = true
    "navidrome.cute.haus"      = true
    "nextcloud.cute.haus"      = false
    "ombi.cute.haus"           = true
    "paperless.cute.haus"      = false
    "pds.cute.haus"            = false
    "photoprism.cute.haus"     = false
    "plex.cute.haus"           = false
    "slingshot.cute.haus"      = true
    "status.cute.haus"         = true
    "vault.cute.haus"          = true
  }
}

resource "cloudflare_dns_record" "cute_haus_a" {
  for_each = local.cute_haus_ingress
  zone_id  = local.zones.cute_haus
  name     = each.key
  type     = "A"
  content  = local.hosts.pastoria
  proxied  = each.value
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
