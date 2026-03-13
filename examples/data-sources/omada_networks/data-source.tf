data "omada_networks" "all" {}

output "networks" {
  value = data.omada_networks.all.networks
}
