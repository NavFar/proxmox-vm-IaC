locals {


  normalized_vms = {
    for name, vm in var.vms : name => {
      name        = name
      description = "${vm.environment}/${vm.role}"

      node_name = (
        vm.placement.policy == "preferred_node"
        ? vm.placement.node
        : var.default_node
      )

      cpu_cores = var.size_profiles[vm.size].cpu_cores
      memory_mb = var.size_profiles[vm.size].memory_mb

      template_id = var.os_profiles[vm.os].template_id
      username    = var.os_profiles[vm.os].username
      public_keys = var.os_profiles[vm.os].public_keys

      bridge = vm.network.primary.bridge
      vlan   = try(vm.network.primary.vlan, null)
      ipv4   = vm.network.primary.ipv4

      root_disk_size_gb = vm.disks.root.size_gb
      root_datastore_id = var.disk_classes[vm.disks.root.class].datastore_id
      root_disk_interface = var.disk_classes[vm.disks.root.class].interface

      tags = distinct(concat(
        ["managed-by-terraform", vm.environment, vm.role],
        try(vm.tags, [])
      ))
    }
  }
}


