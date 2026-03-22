
data "ovh_me" "main_account" {}

resource "ovh_vps" "main_vps" {
  display_name = "main_vps"
  plan         = []
  model = {
    available_options      = []
    datacenter             = []
    disk                   = 200
    maximum_additionnal_ip = 16
    memory                 = 24576
    name                   = "vps-2025-model3"
    offer                  = "VPS-3"
    vcore                  = 8
    version                = "2025v1"
  }
  netboot_mode         = "local"
  sla_monitoring       = false
  vcore                = 8
  zone                 = "Region OpenStack: os-eu-west-rbx-vps-1"
  memory_limit         = 24576
  monitoring_ip_blocks = []
  offer_type           = "ssd"
  # duration     = "P1Y"
  # plan_code    = "vps-2025-model3"
  # pricing_mode = "default"
  # label = "vps_os"
  # value = "Debian 13"

}

resource "ovh_domain_name" "root_domain" {
  domain_name = "fxhibon.fr"
}

resource "ovh_domain_zone_record" "home_subdomain" {
  zone      = ovh_domain_name.root_domain.domain_name
  subdomain = "home"
  fieldtype = "A"
  ttl       = 3600
  target    = local.home_ip_v4
}

resource "ovh_cloud_project_user" "s3_user" {
  service_name = var.ovh_cloud_project_id
  description  = "S3 user for Tofu backend"
  role_names   = ["objectstore_operator"]
}

resource "ovh_cloud_project_user_s3_credential" "s3_creds" {
  service_name = var.ovh_cloud_project_id
  user_id      = ovh_cloud_project_user.s3_user.id
}

resource "ovh_cloud_project_region_storage_container" "tofu_state" {
  service_name = var.ovh_cloud_project_id
  region       = var.ovh_region
  name         = "tofu-state-bucket"
  storage_type = "s3"
}

output "vps_id" {
  value = ovh_vps.main_vps.id
}

output "vps_display_name" {
  value = ovh_vps.main_vps.display_name
}


output "vps_name" {
  value = ovh_vps.main_vps.name
}


