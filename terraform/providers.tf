terraform {
  required_version = ">= 1.5"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.48"
    }
  }
}

provider "cloudflare" {
  # Reads CLOUDFLARE_API_TOKEN from the environment.
}

provider "hcloud" {
  # Reads HCLOUD_TOKEN from the environment.
}
