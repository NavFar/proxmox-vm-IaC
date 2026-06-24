locals {
  cluster_nodes = toset(data.proxmox_virtual_environment_nodes.cluster.names)

  cluster_online_nodes = toset([
    for idx, name in data.proxmox_virtual_environment_nodes.cluster.names :
    name
    if data.proxmox_virtual_environment_nodes.cluster.online[idx]
  ])

  normalized_vms = {
    for name, vm in var.vms : name => {
      name        = name
      description = "${vm.environment}/${vm.role}"

      node_name = (
        vm.placement.policy == "preferred_node"
        ? vm.placement.node
        : var.default_node
      )
      ha = {
        enabled      = try(vm.placement.ha.enabled, false)
        state        = try(vm.placement.ha.state, "started")
        max_restart  = try(vm.placement.ha.max_restart, 3)
        max_relocate = try(vm.placement.ha.max_relocate, 2)
        failback     = try(vm.placement.ha.failback, null)
        node_affinity = {
          enabled = try(vm.placement.ha.node_affinity.enabled, false)
          strict  = try(vm.placement.ha.node_affinity.strict, false)
          nodes   = try(vm.placement.ha.node_affinity.nodes, {})
        }
      }
      cpu_cores = var.size_profiles[vm.size].cpu_cores
      memory_mb = var.size_profiles[vm.size].memory_mb

      template_id   = var.os_profiles[vm.os].template_id
      template_node = var.os_profiles[vm.os].template_node
      username      = var.os_profiles[vm.os].username
      public_keys   = var.os_profiles[vm.os].public_keys

      bridge = vm.network.primary.bridge
      vlan   = try(vm.network.primary.vlan, null)
      ipv4   = vm.network.primary.ipv4

      root_disk_size_gb   = vm.disks.root.size_gb
      root_datastore_id   = var.disk_classes[vm.disks.root.class].datastore_id
      root_disk_interface = var.disk_classes[vm.disks.root.class].interface

      tags = distinct(concat(
        ["managed-by-terraform", vm.environment, vm.role],
        try(vm.tags, [])
      ))
    }
  }
  ha_vms = {
    for name, vm in local.normalized_vms : name => vm
    if vm.ha.enabled
  }
  ha_node_affinity_rules = {
    for name, vm in local.normalized_vms : name => vm
    if vm.ha.enabled && vm.ha.node_affinity.enabled
  }
  enabled_ha_resource_rules = {
    for name, rule in var.ha_resource_rules : name => rule
    if try(rule.enabled, true)
  }
  vms_in_ha_resource_rules = toset(distinct(flatten([
    for rule_name, rule in local.enabled_ha_resource_rules :
    rule.resources
  ])))
}


