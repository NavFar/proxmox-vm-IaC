output "vms" {
  description = "VM details:"
  value       = module.proxmox_vm_fleet.vms
}
output "resource_affinity" {
  description = "resource affinity details"
  value       = module.proxmox_vm_fleet.ha_resource_rules
}
output "storage_inventory" {
  value = module.proxmox_vm_fleet.storage_inventory
}
output "replications" {
  description = "Proxmox replication jobs."
  value       = module.proxmox_vm_fleet.replications
}
