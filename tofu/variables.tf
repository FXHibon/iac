variable "ovh_application_key" {
  type = string
}

variable "ovh_application_secret" {
  type = string
}

variable "ovh_consumer_key" {
  type = string
}

variable "ovh_cloud_project_id" {
  type        = string
  description = "The ID of the OVH Public Cloud project (service_name)"
}

variable "ovh_region" {
  type    = string
  default = "GRA"
}

locals {
  # This is the IP address of my home network (Freebox)
  home_ip_v4 = "REDACTED_HOME_IP_OLD"
}
