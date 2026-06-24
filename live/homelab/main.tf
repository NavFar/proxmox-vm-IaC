module "vms" {
  source       = "../../modules/proxmox-bpg-vm"
  default_node = var.default_node
  vms          = var.vms
  size_profiles = local.size_profiles
  os_profiles = local.os_profiles
  disk_classes = local.disk_classes
  ha_resource_rules = var.ha_resource_rules
}
