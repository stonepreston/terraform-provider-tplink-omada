data "omada_port_profiles" "all" {}

output "port_profiles" {
  value = data.omada_port_profiles.all.port_profiles
}
