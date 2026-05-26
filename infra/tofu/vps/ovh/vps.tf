
resource "ovh_vps" "main_vps" {
  display_name         = "main_vps"
  do_not_send_password = null
  image_id             = null
  keymap               = null
  memory_limit         = 24576
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
  monitoring_ip_blocks = []
  name                 = "vps-04e57c0c.vps.ovh.net"
  netboot_mode         = "local"
  offer_type           = "ssd"
  ovh_subsidiary       = null
  plan = [
  ]
  plan_option    = null
  public_ssh_key = null
  sla_monitoring = false
  state          = "running"
  vcore          = 8
  zone           = "Region OpenStack: os-eu-west-rbx-vps-1"
}
