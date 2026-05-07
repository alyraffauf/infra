resource "cloudflare_dns_record" "cute_haus_apex_a_solaceon" {
  zone_id  = local.zones.cute_haus
  name     = "cute.haus"
  type     = "A"
  content  = local.hosts.solaceon
  proxied  = true
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "cute_haus_apex_a_celestic" {
  zone_id  = local.zones.cute_haus
  name     = "cute.haus"
  type     = "A"
  content  = local.hosts.celestic
  proxied  = true
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "cute_haus_audiobookshelf_a_solaceon" {
  zone_id  = local.zones.cute_haus
  name     = "audiobookshelf.cute.haus"
  type     = "A"
  content  = local.hosts.solaceon
  proxied  = true
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "cute_haus_audiobookshelf_a_celestic" {
  zone_id  = local.zones.cute_haus
  name     = "audiobookshelf.cute.haus"
  type     = "A"
  content  = local.hosts.celestic
  proxied  = true
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "cute_haus_couchdb_a" {
  zone_id  = local.zones.cute_haus
  name     = "couchdb.cute.haus"
  type     = "A"
  content  = "34.203.252.172"
  proxied  = true
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "cute_haus_immich_a_solaceon" {
  zone_id  = local.zones.cute_haus
  name     = "immich.cute.haus"
  type     = "A"
  content  = local.hosts.solaceon
  proxied  = true
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "cute_haus_immich_a_celestic" {
  zone_id  = local.zones.cute_haus
  name     = "immich.cute.haus"
  type     = "A"
  content  = local.hosts.celestic
  proxied  = true
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

resource "cloudflare_dns_record" "cute_haus_ombi_a_solaceon" {
  zone_id  = local.zones.cute_haus
  name     = "ombi.cute.haus"
  type     = "A"
  content  = local.hosts.solaceon
  proxied  = true
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "cute_haus_ombi_a_celestic" {
  zone_id  = local.zones.cute_haus
  name     = "ombi.cute.haus"
  type     = "A"
  content  = local.hosts.celestic
  proxied  = true
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "cute_haus_plex_a_solaceon" {
  zone_id  = local.zones.cute_haus
  name     = "plex.cute.haus"
  type     = "A"
  content  = local.hosts.solaceon
  proxied  = true
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "cute_haus_plex_a_celestic" {
  zone_id  = local.zones.cute_haus
  name     = "plex.cute.haus"
  type     = "A"
  content  = local.hosts.celestic
  proxied  = true
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "cute_haus_status_a_solaceon" {
  zone_id  = local.zones.cute_haus
  name     = "status.cute.haus"
  type     = "A"
  content  = local.hosts.solaceon
  proxied  = true
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "cute_haus_status_a_celestic" {
  zone_id  = local.zones.cute_haus
  name     = "status.cute.haus"
  type     = "A"
  content  = local.hosts.celestic
  proxied  = true
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "cute_haus_vault_a_solaceon" {
  zone_id  = local.zones.cute_haus
  name     = "vault.cute.haus"
  type     = "A"
  content  = local.hosts.solaceon
  proxied  = true
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "cute_haus_vault_a_celestic" {
  zone_id  = local.zones.cute_haus
  name     = "vault.cute.haus"
  type     = "A"
  content  = local.hosts.celestic
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
  proxied = true
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

moved {
  from = cloudflare_dns_record.terraform_managed_resource_9db1347e9bfbb9b94ddc2c6beebfbbec_0
  to   = cloudflare_dns_record.cute_haus_audiobookshelf_a_solaceon
}

moved {
  from = cloudflare_dns_record.terraform_managed_resource_7ab4d87d1f252e2611da202ac6b3660c_1
  to   = cloudflare_dns_record.cute_haus_couchdb_a
}

moved {
  from = cloudflare_dns_record.terraform_managed_resource_c120a07d394419cfc6c9561df0a861b6_2
  to   = cloudflare_dns_record.cute_haus_apex_a_solaceon
}

moved {
  from = cloudflare_dns_record.terraform_managed_resource_2407a00df235bf967ae926fc2127c045_3
  to   = cloudflare_dns_record.cute_haus_immich_a_solaceon
}

moved {
  from = cloudflare_dns_record.terraform_managed_resource_d3d3ca7fd3dd876df30dcf70c9106530_5
  to   = cloudflare_dns_record.cute_haus_navidrome_a
}

moved {
  from = cloudflare_dns_record.terraform_managed_resource_c171e686577dbcc642e4cd15e3b67fa8_6
  to   = cloudflare_dns_record.cute_haus_ombi_a_solaceon
}

moved {
  from = cloudflare_dns_record.terraform_managed_resource_c7784c1909c355580a8fd0ba4bfa9b9d_7
  to   = cloudflare_dns_record.cute_haus_plex_a_solaceon
}

moved {
  from = cloudflare_dns_record.terraform_managed_resource_c1cd0c04348d3bdf05a6d343db5c9c64_8
  to   = cloudflare_dns_record.cute_haus_status_a_solaceon
}

moved {
  from = cloudflare_dns_record.terraform_managed_resource_7fe142cdf44b3826ce28f5414c633f53_9
  to   = cloudflare_dns_record.cute_haus_vault_a_solaceon
}

moved {
  from = cloudflare_dns_record.terraform_managed_resource_640bb870f256e3528038f828e6354015_10
  to   = cloudflare_dns_record.cute_haus_www_cname
}

moved {
  from = cloudflare_dns_record.terraform_managed_resource_a57e0feb23f34c295a98edf71563d8e2_11
  to   = cloudflare_dns_record.cute_haus_atproto_txt
}

moved {
  from = cloudflare_dns_record.terraform_managed_resource_731a96ccdf34e6a5df82602f6e90838e_12
  to   = cloudflare_dns_record.cute_haus_apex_google_verify_txt
}
