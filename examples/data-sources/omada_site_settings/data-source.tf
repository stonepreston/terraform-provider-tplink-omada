data "omada_site_settings" "current" {}

output "mesh_enabled" {
  value = data.omada_site_settings.current.mesh_enable
}

output "fast_roaming_enabled" {
  value = data.omada_site_settings.current.fast_roaming_enable
}
