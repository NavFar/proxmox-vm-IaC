output "vms" {
  description = "Created VMs indexed by business VM name."

  value = {
    for name, vm in proxmox_virtual_environment_vm.this : name => {
      vm_id        = vm.vm_id
      name         = vm.name
      node_name    = vm.node_name

      ipv4_addresses = try(flatten(vm.ipv4_addresses), [])
      ipv6_addresses = try(flatten(vm.ipv6_addresses), [])
    }
  }
}
