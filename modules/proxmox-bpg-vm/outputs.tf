output "vms" {
  description = "Created VMs indexed by business VM name."

  value = {
    for name, vm in proxmox_virtual_environment_vm.this : name => {
      vm_id     = vm.vm_id
      name      = vm.name
      node_name = vm.node_name

      desired_ipv4 = local.normalized_vms[name].ipv4.address
      desired_gateway = try(local.normalized_vms[name].ipv4.gateway, null)

      discovered_ipv4_addresses = try(flatten(vm.ipv4_addresses), [])

      primary_ipv4 = (
        length(try(flatten(vm.ipv4_addresses), [])) > 0
        ? flatten(vm.ipv4_addresses)[0]
        : local.normalized_vms[name].ipv4.address != "dhcp"
          ? local.normalized_vms[name].ipv4.address
          : null
      )
    }
  }
}
