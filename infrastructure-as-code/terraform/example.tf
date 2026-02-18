variable "exoscale_key" {
  description = "The key for the exoscale account."
  type        = string
}
variable "exoscale_secret" {
  description = "The secret for the exoscale account"
  type        = string
}

terraform {
  required_providers {
    exoscale = {
      source = "exoscale/exoscale"
    }
  }

  backend "s3" {
    endpoints = {
      s3 = "https://sos-ch-dk-2.exo.io"
    }
    bucket                      = "latzo-tfstate"
    key                         = "dns/tofu.tfstate"
    region                      = "ch-dk-2"
    access_key                  = var.exoscale_key
    secret_key                  = var.exoscale_secret
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
  }
}

provider "exoscale" {
  key    = var.exoscale_key
  secret = var.exoscale_secret
}

resource "exoscale_domain" "polaris" {
  name = "polaris-inspire.ch"
}