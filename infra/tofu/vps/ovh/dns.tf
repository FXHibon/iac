
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

# Traefik Dashboard Entry (traefik.vps.fxhibon.fr)
resource "ovh_domain_zone_record" "traefik_vps_record_v4" {
  zone      = ovh_domain_name.root_domain.domain_name
  subdomain = "traefik"
  fieldtype = "A"
  ttl       = 3600
  target    = tolist(data.ovh_vps.main_vps.ips)[1]
}

# Prometheus Dashboard Entry (prometheus.vps.fxhibon.fr)
resource "ovh_domain_zone_record" "prometheus_vps_record_v4" {
  zone      = ovh_domain_name.root_domain.domain_name
  subdomain = "prometheus"
  fieldtype = "A"
  ttl       = 3600
  target    = tolist(data.ovh_vps.main_vps.ips)[1]
}

# Grafana Dashboard Entry (grafana.vps.fxhibon.fr)
resource "ovh_domain_zone_record" "grafana_vps_record_v4" {
  zone      = ovh_domain_name.root_domain.domain_name
  subdomain = "grafana"
  fieldtype = "A"
  ttl       = 3600
  target    = tolist(data.ovh_vps.main_vps.ips)[1]
}


# Wildcard for all other services on the VPS (e.g. *.vps.fxhibon.fr)
resource "ovh_domain_zone_record" "wildcard_vps_record_v4" {
  zone      = ovh_domain_name.root_domain.domain_name
  subdomain = "*"
  fieldtype = "A"
  ttl       = 3600
  target    = tolist(data.ovh_vps.main_vps.ips)[1]
}

resource "ovh_domain_zone_record" "wildcard_vps_record_v6" {
  zone      = ovh_domain_name.root_domain.domain_name
  subdomain = "*"
  fieldtype = "AAAA"
  ttl       = 3600
  target    = tolist(data.ovh_vps.main_vps.ips)[0]
}
