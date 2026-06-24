output "vms" {
  description = "VM details:"
  value       = module.proxmox_vm_fleet.vms
}
output "resource_affinity"{
  description = "resource affinity details"
  value       = module.proxmox_vm_fleet.ha_resource_rules
}
