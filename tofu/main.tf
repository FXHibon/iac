
data "ovh_me" "main_account" {}

data "ovh_order_cart" "main_cart" {
  ovh_subsidiary = data.ovh_me.main_account.ovh_subsidiary
}

resource "ovh_vps" "main_vps" {
  name         = "main_vps"
  display_name = "main_vps"

  ovh_subsidiary = data.ovh_order_cart.main_cart.ovh_subsidiary
  plan = [
    {
      duration     = "P1Y"
      plan_code    = "vps-2025-model3"
      pricing_mode = "default"


      configuration = [
        {
          label = "vps_datacenter"
          value = "EU-WEST-RBX"
        },
        {
          label = "vps_os"
          value = "Debian 13"
        }
      ]
    }
  ]

  public_ssh_key = file("~/.ssh/id_ovh_vps.pub")
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


