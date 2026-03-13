# Omada Controller connection
# These can also be set via environment variables:
#   OMADA_URL, OMADA_USERNAME, OMADA_PASSWORD, OMADA_SITE

terraform {
  required_providers {
    omada = {
      source = "registry.terraform.io/tplink/omada"
    }
  }
}

provider "omada" {
  url             = "https://192.168.1.1:8043"
  username        = "admin"
  password        = var.omada_password
  site            = "Default"
  skip_tls_verify = true
}

variable "omada_password" {
  type      = string
  sensitive = true
}

# -------------------------------------------------------
# Data Sources — look up existing resources
# -------------------------------------------------------

data "omada_sites" "all" {}

data "omada_networks" "all" {}

# -------------------------------------------------------
# Networks (VLANs)
# -------------------------------------------------------

resource "omada_network" "trusted" {
  name         = "Trusted"
  vlan_id      = 10
  subnet       = "192.168.10.0"
  cidr         = 24
  gateway_ip   = "192.168.10.1"
  dhcp_enabled = true
  dhcp_start   = "192.168.10.100"
  dhcp_end     = "192.168.10.254"
}

resource "omada_network" "iot" {
  name         = "IoT"
  vlan_id      = 20
  subnet       = "192.168.20.0"
  cidr         = 24
  gateway_ip   = "192.168.20.1"
  dhcp_enabled = true
  dhcp_start   = "192.168.20.100"
  dhcp_end     = "192.168.20.254"
}

resource "omada_network" "guest" {
  name         = "Guest"
  vlan_id      = 30
  subnet       = "192.168.30.0"
  cidr         = 24
  gateway_ip   = "192.168.30.1"
  dhcp_enabled = true
  dhcp_start   = "192.168.30.100"
  dhcp_end     = "192.168.30.254"
}

# -------------------------------------------------------
# Wireless Networks (SSIDs)
# -------------------------------------------------------

resource "omada_wireless_network" "home_wifi" {
  name       = "HomeWiFi"
  band       = 3 # Both 2.4GHz + 5GHz
  security   = 3 # WPA2/WPA3
  passphrase = var.wifi_home_password
  broadcast  = true
  vlan_id    = omada_network.trusted.vlan_id
  enable_11r = true # Fast roaming
  pmf_mode   = 2    # Optional PMF
}

resource "omada_wireless_network" "iot_wifi" {
  name       = "IoT-Devices"
  band       = 1 # 2.4GHz only (better for IoT)
  security   = 3
  passphrase = var.wifi_iot_password
  broadcast  = false # Hidden SSID
  vlan_id    = omada_network.iot.vlan_id
}

resource "omada_wireless_network" "guest_wifi" {
  name       = "Guest"
  band       = 3
  security   = 3
  passphrase = var.wifi_guest_password
  broadcast  = true
  vlan_id    = omada_network.guest.vlan_id
}

variable "wifi_home_password" {
  type      = string
  sensitive = true
}

variable "wifi_iot_password" {
  type      = string
  sensitive = true
}

variable "wifi_guest_password" {
  type      = string
  sensitive = true
}

# -------------------------------------------------------
# Port Profiles
# -------------------------------------------------------

resource "omada_port_profile" "trunk_all" {
  name              = "Trunk-All"
  native_network_id = omada_network.trusted.id
  tag_network_ids = [
    omada_network.iot.id,
    omada_network.guest.id,
  ]
  poe                  = 1
  spanning_tree_enable = true
}

resource "omada_port_profile" "iot_access" {
  name              = "IoT-Access"
  native_network_id = omada_network.iot.id
  poe               = 1
}

# -------------------------------------------------------
# Firewall Rules (Gateway ACLs)
# -------------------------------------------------------

# Block IoT devices from reaching the Trusted network
resource "omada_firewall_rule" "deny_iot_to_trusted" {
  name             = "Deny-IoT-to-Trusted"
  policy           = 0          # Deny
  protocols        = [6, 17, 1] # TCP, UDP, ICMP
  source_type      = 0          # Network
  source_ids       = [omada_network.iot.id]
  destination_type = 0
  destination_ids  = [omada_network.trusted.id]
  lan_to_lan       = true
  lan_to_wan       = false
}

# Block Guest from reaching any internal network
resource "omada_firewall_rule" "deny_guest_to_internal" {
  name             = "Deny-Guest-to-Internal"
  policy           = 0
  protocols        = [6, 17, 1]
  source_type      = 0
  source_ids       = [omada_network.guest.id]
  destination_type = 0
  destination_ids = [
    omada_network.trusted.id,
    omada_network.iot.id,
  ]
  lan_to_lan = true
  lan_to_wan = false
}

# -------------------------------------------------------
# Static Routes
# -------------------------------------------------------

resource "omada_static_route" "vpn_remote_office" {
  name        = "VPN-Remote-Office"
  destination = "10.10.0.0"
  cidr        = 16
  next_hop    = "192.168.1.254"
  distance    = 1
}

# -------------------------------------------------------
# DHCP Reservations
# -------------------------------------------------------

resource "omada_dhcp_reservation" "nas" {
  network_id  = omada_network.trusted.id
  mac         = "AA-BB-CC-DD-EE-01"
  ip          = "192.168.10.10"
  description = "NAS Server"
}

resource "omada_dhcp_reservation" "printer" {
  network_id  = omada_network.trusted.id
  mac         = "AA-BB-CC-DD-EE-02"
  ip          = "192.168.10.11"
  description = "Network Printer"
}

# -------------------------------------------------------
# Outputs
# -------------------------------------------------------

output "sites" {
  value = data.omada_sites.all.sites
}

output "trusted_network_id" {
  value = omada_network.trusted.id
}

output "iot_network_id" {
  value = omada_network.iot.id
}
