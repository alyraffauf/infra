resource "cloudflare_dns_record" "aly_codes_apex_a_solaceon" {
  zone_id  = local.zones.aly_codes
  name     = "aly.codes"
  type     = "A"
  content  = local.hosts.solaceon
  proxied  = true
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "aly_codes_git_a_solaceon" {
  zone_id  = local.zones.aly_codes
  name     = "git.aly.codes"
  type     = "A"
  content  = local.hosts.solaceon
  proxied  = true
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "aly_codes_ssh_a" {
  zone_id  = local.zones.aly_codes
  name     = "ssh.aly.codes"
  type     = "A"
  content  = local.hosts.solaceon
  proxied  = false
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "aly_codes_status_a_solaceon" {
  zone_id  = local.zones.aly_codes
  name     = "status.aly.codes"
  type     = "A"
  content  = local.hosts.solaceon
  proxied  = true
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "aly_codes_vibes_a_solaceon" {
  zone_id  = local.zones.aly_codes
  name     = "vibes.aly.codes"
  type     = "A"
  content  = local.hosts.solaceon
  proxied  = true
  ttl      = 1
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "aly_codes_fm1_dkim_cname" {
  zone_id = local.zones.aly_codes
  name    = "fm1._domainkey.aly.codes"
  type    = "CNAME"
  content = "fm1.aly.codes.dkim.fmhosted.com"
  proxied = false
  ttl     = 1
  tags    = []
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "aly_codes_fm2_dkim_cname" {
  zone_id = local.zones.aly_codes
  name    = "fm2._domainkey.aly.codes"
  type    = "CNAME"
  content = "fm2.aly.codes.dkim.fmhosted.com"
  proxied = false
  ttl     = 1
  tags    = []
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "aly_codes_fm3_dkim_cname" {
  zone_id = local.zones.aly_codes
  name    = "fm3._domainkey.aly.codes"
  type    = "CNAME"
  content = "fm3.aly.codes.dkim.fmhosted.com"
  proxied = false
  ttl     = 1
  tags    = []
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

moved {
  from = cloudflare_dns_record.terraform_managed_resource_c32f557b697af12c9e2f3afa8f3eed88_0
  to   = cloudflare_dns_record.aly_codes_apex_a_solaceon
}

moved {
  from = cloudflare_dns_record.terraform_managed_resource_dac92f1d46ff045dab9f8bd304e69c8b_2
  to   = cloudflare_dns_record.aly_codes_git_a_solaceon
}

moved {
  from = cloudflare_dns_record.terraform_managed_resource_140b4f9f638a15bc846ae60ddf7cb7ca_4
  to   = cloudflare_dns_record.aly_codes_ssh_a
}

moved {
  from = cloudflare_dns_record.terraform_managed_resource_62b0929822987fcdc27689bceae3e89f_5
  to   = cloudflare_dns_record.aly_codes_status_a_solaceon
}

moved {
  from = cloudflare_dns_record.terraform_managed_resource_726497c904a3f69d4c02e1bb3a39515a_6
  to   = cloudflare_dns_record.aly_codes_vibes_a_solaceon
}

moved {
  from = cloudflare_dns_record.terraform_managed_resource_01673992370bc5c94eadfeaa3cfb0ea9_7
  to   = cloudflare_dns_record.aly_codes_fm1_dkim_cname
}

moved {
  from = cloudflare_dns_record.terraform_managed_resource_7602f2efc875d5bf3f117ec56a1e3af0_8
  to   = cloudflare_dns_record.aly_codes_fm2_dkim_cname
}

moved {
  from = cloudflare_dns_record.terraform_managed_resource_7fbb61d96d3b15779104b282282e37fd_9
  to   = cloudflare_dns_record.aly_codes_fm3_dkim_cname
}

moved {
  from = cloudflare_dns_record.terraform_managed_resource_883966d176baf949e2ae19bc251b291e_10
  to   = cloudflare_dns_record.aly_codes_switchyard_cname
}

moved {
  from = cloudflare_dns_record.terraform_managed_resource_9815929bce95eeb9d9c5893edf607582_11
  to   = cloudflare_dns_record.aly_codes_www_cname
}

moved {
  from = cloudflare_dns_record.terraform_managed_resource_56c10ff3e05e52b254cd6886c5c0987c_13
  to   = cloudflare_dns_record.aly_codes_apex_mx_10
}

moved {
  from = cloudflare_dns_record.terraform_managed_resource_276ca8c060c4c1d4101a1de01aa265f9_12
  to   = cloudflare_dns_record.aly_codes_apex_mx_20
}

moved {
  from = cloudflare_dns_record.terraform_managed_resource_2364dc576fc9a888ba0d082207de2c7a_14
  to   = cloudflare_dns_record.aly_codes_apex_google_verify_txt
}

moved {
  from = cloudflare_dns_record.terraform_managed_resource_9d6bb24bc73e7b09694217cc6772e2bd_15
  to   = cloudflare_dns_record.aly_codes_apex_spf_txt
}

moved {
  from = cloudflare_dns_record.terraform_managed_resource_7f525224e0260608ea571e3127a4c3e0_16
  to   = cloudflare_dns_record.aly_codes_atproto_txt
}
