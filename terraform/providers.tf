terraform {
  required_version = ">= 1.10"

  required_providers {
    b2 = {
      source  = "Backblaze/b2"
      version = "~> 0.13"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.29"
    }
  }

  # State in B2 alongside CNPG + Longhorn backups. Auth via AWS_ACCESS_KEY_ID /
  # AWS_SECRET_ACCESS_KEY (B2 application key in secrets/b2.yaml). Bucket has
  # versioning enabled, so state history is recoverable from B2 if a bad apply
  # corrupts it.
  #
  # No state locking: B2's S3 API at us-east-005 doesn't honor the
  # If-None-Match conditional-PUT header that terraform's use_lockfile uses
  # (501 NotImplemented). DynamoDB-based locking is overkill for single-user
  # operation; the discipline is "don't run terraform from two places at once."
  backend "s3" {
    bucket = "aly-backups"
    key    = "cute.haus/terraform/terraform.tfstate"
    region = "us-east-005"

    endpoints = {
      s3 = "https://s3.us-east-005.backblazeb2.com"
    }

    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = true
    skip_s3_checksum            = true
  }
}

provider "cloudflare" {
  # Reads CLOUDFLARE_API_TOKEN from the environment.
}

provider "b2" {
  # Reads B2_APPLICATION_KEY_ID and B2_APPLICATION_KEY from the environment.
}

provider "tailscale" {
  # Reads TAILSCALE_API_KEY from the environment (API key in
  # secrets/tailscale-api.yaml, decrypted by direnv).
}
