terraform {
  required_version = ">= 1.6.0"

  required_providers {

    sops = {
      source  = "carlpett/sops"
      version = "1.4.1"
    }

    ovh = {
      source  = "ovh/ovh"
      version = "2.13.1"
    }
  }
}

provider "ovh" {
  endpoint           = "ovh-eu"
  application_key    = data.sops_file.secrets.data["ovh.application_key"]
  application_secret = data.sops_file.secrets.data["ovh.application_secret"]
  consumer_key       = data.sops_file.secrets.data["ovh.consumer_key"]
}
