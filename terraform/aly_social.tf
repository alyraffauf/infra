resource "cloudflare_dns_record" "aly_social_wildcard_a" {
  zone_id  = local.zones.aly_social
  name     = "*.aly.social"
  type     = "A"
  content  = local.hosts.celestic
  proxied  = false
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "aly_social_apex_a_solaceon" {
  zone_id  = local.zones.aly_social
  name     = "aly.social"
  type     = "A"
  content  = local.hosts.solaceon
  proxied  = true
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "aly_social_status_a_solaceon" {
  zone_id  = local.zones.aly_social
  name     = "status.aly.social"
  type     = "A"
  content  = local.hosts.solaceon
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

moved {
  from = cloudflare_dns_record.terraform_managed_resource_fc275b5e1eca07f893f2a6d739d0468c_0
  to   = cloudflare_dns_record.aly_social_wildcard_a
}

moved {
  from = cloudflare_dns_record.terraform_managed_resource_28b36b0da1355a87d53cf6b88e4c9a17_1
  to   = cloudflare_dns_record.aly_social_apex_a_solaceon
}

moved {
  from = cloudflare_dns_record.terraform_managed_resource_653941724e7504acb90b17ca6630297c_2
  to   = cloudflare_dns_record.aly_social_status_a_solaceon
}

moved {
  from = cloudflare_dns_record.terraform_managed_resource_139a14bd75af9e1bd468a6d717906bc0_3
  to   = cloudflare_dns_record.aly_social_send_mx
}

moved {
  from = cloudflare_dns_record.terraform_managed_resource_2c41030ec83e43a02b9f084fdd26b846_4
  to   = cloudflare_dns_record.aly_social_ruffruff_atproto_txt
}

moved {
  from = cloudflare_dns_record.terraform_managed_resource_832684ace418e58babc33efd81a38596_5
  to   = cloudflare_dns_record.aly_social_resend_dkim_txt
}

moved {
  from = cloudflare_dns_record.terraform_managed_resource_4c314e89c5b0df97630a97c210f04f22_6
  to   = cloudflare_dns_record.aly_social_send_spf_txt
}
