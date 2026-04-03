terraform {
  backend "s3" {

    # REQUIRED ENV:
    # - AWS_ACCESS_KEY_ID
    # - AWS_SECRET_ACCESS_KEY

    bucket = "hulking-weinberg"
    key    = "vps/tofu/bucket/hulking-weinberg"
    region = "rbx"

    endpoints = {
      s3 = "https://s3.rbx.io.cloud.ovh.net"
    }

    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}
