
resource "ovh_domain_name" "root_domain" {
  domain_name = "fxhibon.fr"
}

resource "ovh_domain_zone_record" "home_subdomain_v4" {
  zone      = ovh_domain_name.root_domain.domain_name
  subdomain = "home"
  fieldtype = "A"
  ttl       = 3600
  target    = data.sops_file.secrets.data["home_ip_v4"]
}

data "ovh_vps" "main_vps" {
  service_name = ovh_vps.main_vps.service_name
}

resource "ovh_domain_zone_record" "vps_record_v4" {
  zone      = ovh_domain_name.root_domain.domain_name
  subdomain = "vps"
  fieldtype = "A"
  ttl       = 3600

  # index:0 ipv6
  # index:1 ipv4
  target = tolist(data.ovh_vps.main_vps.ips)[1]
}

resource "ovh_domain_zone_record" "vps_record_v6" {
  zone      = ovh_domain_name.root_domain.domain_name
  subdomain = "vps"
  fieldtype = "AAAA"
  ttl       = 3600

  # index:0 ipv6
  # index:1 ipv4
  target = tolist(data.ovh_vps.main_vps.ips)[0]
}
