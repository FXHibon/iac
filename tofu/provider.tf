terraform {
  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = "2.12.0"
    }
  }
}

provider "ovh" {
  endpoint           = "ovh-eu"
  application_key    = var.ovh_application_key
  application_secret = var.ovh_application_secret
  consumer_key       = var.ovh_consumer_key
}

/*
# After creating the bucket and the s3_user with 'tofu apply', 
# you can configure the remote backend like this.
# You'll need to use 'tofu init -backend-config="access_key=..." -backend-config="secret_key=..."'
# to pass the credentials without storing them in this file.

terraform {
  backend "s3" {
    bucket                      = "tofu-state-bucket"
    key                         = "tofu.tfstate"
    region                      = "GRA" # Must match your OVH region
    endpoint                    = "https://s3.gra.cloud.ovh.net" # Update based on region
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
  }
}
*/
