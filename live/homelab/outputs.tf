output "vms" {
  description = "VM details:"
  value       = module.vms.vms
}
output "resource_affinity"{
  description = "resource affinity details"
  value       = module.vms.ha_resource_rules
}
