# List all SSIDs across all WLAN groups
data "omada_wireless_networks" "all" {}

# Or filter by a specific WLAN group
data "omada_wireless_networks" "default_group" {
  wlan_group_id = "696a40fd49039e1d13a9c412"
}

output "wireless_networks" {
  value = data.omada_wireless_networks.all.wireless_networks
}
