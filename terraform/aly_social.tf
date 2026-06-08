resource "cloudflare_dns_record" "aly_social_wildcard_a" {
  zone_id  = local.zones.aly_social
  name     = "*.aly.social"
  type     = "A"
  content  = local.hosts.pastoria
  proxied  = false
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "aly_social_apex_a" {
  zone_id  = local.zones.aly_social
  name     = "aly.social"
  type     = "A"
  content  = local.hosts.pastoria
  proxied  = true
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "aly_social_status_a" {
  zone_id  = local.zones.aly_social
  name     = "status.aly.social"
  type     = "A"
  content  = local.hosts.pastoria
  proxied  = true
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "aly_social_send_mx" {
  zone_id  = local.zones.aly_social
  name     = "send.aly.social"
  type     = "MX"
  content  = "feedback-smtp.us-east-1.amazonses.com"
  priority = 10
  proxied  = false
  ttl      = 3600
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "aly_social_ruffruff_atproto_txt" {
  zone_id  = local.zones.aly_social
  name     = "_atproto.ruffruff.aly.social"
  type     = "TXT"
  content  = "\"did=did:plc:j4l6qmi2jja32k7q2zojm3fc\""
  proxied  = false
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "aly_social_resend_dkim_txt" {
  zone_id  = local.zones.aly_social
  name     = "resend._domainkey.aly.social"
  type     = "TXT"
  content  = "\"p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDX9mensVJFS5Tkyt8Cg4AD5aExHJrg4Ne1Qs5vZXWr2yVZwqJMtpUjli7QcvKtGWdqAXu0yy6/lmjB17ertZ5l1kI3f8wFBxeO2bEM3cu+F88vJBOoboPyUhH8j+tO0SAip5NAdkf0jC/+D4NFemi4rgEeWbk1XdgMk5VTUtuWhQIDAQAB\""
  proxied  = false
  ttl      = 3600
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "aly_social_send_spf_txt" {
  zone_id  = local.zones.aly_social
  name     = "send.aly.social"
  type     = "TXT"
  content  = "\"v=spf1 include:amazonses.com -all\""
  proxied  = false
  ttl      = 3600
  tags     = []
  settings = {}
}
