resource "ovh_cloud_project_storage" "backups_storage" {
  service_name = data.sops_file.secrets.data["ovh.cloud_project_id"]
  region_name  = "RBX"
  name         = "backups-fxhibon"
}
