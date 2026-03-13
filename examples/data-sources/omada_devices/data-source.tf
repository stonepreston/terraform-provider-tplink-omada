data "omada_devices" "all" {}

output "devices" {
  value = data.omada_devices.all.devices
}
