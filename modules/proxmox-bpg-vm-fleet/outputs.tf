output "vms" {
  description = "Created VMs indexed by business VM name."

  value = {
    for name, vm in proxmox_virtual_environment_vm.this : name => {
      vm_id     = vm.vm_id
      name      = vm.name
      node_name = vm.node_name

      desired_ipv4    = local.normalized_vms[name].ipv4.address
      desired_gateway = try(local.normalized_vms[name].ipv4.gateway, null)

      discovered_ipv4_addresses = try(flatten(vm.ipv4_addresses), [])

      primary_ipv4 = (
        length(try(flatten(vm.ipv4_addresses), [])) > 0
        ? flatten(vm.ipv4_addresses)[0]
        : local.normalized_vms[name].ipv4.address != "dhcp"
        ? local.normalized_vms[name].ipv4.address
        : null
      )
      ha_enabled = local.normalized_vms[name].ha.enabled
      ha_state = (
        local.normalized_vms[name].ha.enabled
        ? proxmox_haresource.this[name].state
        : null
      )

      ha_node_affinity = (
        local.normalized_vms[name].ha.node_affinity.enabled
        ? {
          strict = local.normalized_vms[name].ha.node_affinity.strict
          nodes  = local.normalized_vms[name].ha.node_affinity.nodes
        }
        : null
      )
    }
  }
}
output "ha_resource_rules" {
  description = "HA resource affinity and anti-affinity rules managed by this module."

  value = {
    for name, rule in proxmox_harule.resource_affinity : name => {
      id        = rule.id
      rule      = rule.rule
      type      = rule.type
      affinity  = try(rule.affinity, null)
      strict    = rule.strict
      disable   = try(rule.disable, null)
      comment   = try(rule.comment, null)
      resources = rule.resources

      input_resources = try(var.ha_resource_rules[name].resources, [])
    }
  }
}
output "storage_inventory" {
  description = "Available image datastores by Proxmox node."
  value = {
    for node_name, datastores in local.datastores_by_node :
    node_name => {
      for datastore_id, datastore in datastores :
      datastore_id => {
        type            = datastore.type
        shared          = try(datastore.shared, null)
        space_total     = try(datastore.space_total, null)
        space_available = try(datastore.space_available, null)
        content_types   = try(datastore.content_types, [])
      }
    }
  }
}

output "replications" {
  description = "Proxmox replication jobs managed by this module."

  value = {
    for name, job in proxmox_replication.this : name => {
      id       = job.id
      guest    = try(job.guest, null)
      jobnum   = try(job.jobnum, null)
      source   = try(job.source, null)
      target   = job.target
      type     = job.type
      schedule = try(job.schedule, null)
      rate     = try(job.rate, null)
      disable  = try(job.disable, null)
      comment  = try(job.comment, null)
    }
  }
}
