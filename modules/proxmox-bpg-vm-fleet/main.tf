resource "proxmox_virtual_environment_vm" "this" {
  for_each = local.normalized_vms

  name        = each.value.name
  description = each.value.description
  node_name   = each.value.node_name
  tags        = each.value.tags

  clone {
    node_name = each.value.template_node
    vm_id     = each.value.template_id
    full      = true
  }

  cpu {
    cores = each.value.cpu_cores
    type  = "host"
  }

  memory {
    dedicated = each.value.memory_mb
  }

  disk {
    datastore_id = each.value.root_datastore_id
    interface    = each.value.root_disk_interface
    size         = each.value.root_disk_size_gb
  }

  network_device {
    bridge  = each.value.bridge
    vlan_id = each.value.vlan
    model   = "virtio"
  }

  agent {
    enabled = false
  }
  stop_on_destroy = true

  initialization {
    datastore_id = each.value.root_datastore_id
    interface    = "ide2"
    upgrade      = false
    user_account {
      username = each.value.username
      keys     = each.value.public_keys
    }

    ip_config {
      ipv4 {
        address = each.value.ipv4.address == "dhcp" ? "dhcp" : each.value.ipv4.address
        gateway = each.value.ipv4.address == "dhcp" ? "" : try(each.value.ipv4.gateway, "")

      }
    }
  }

  lifecycle {
    ignore_changes = [
      node_name
    ]

    precondition {
      condition     = contains(keys(var.os_profiles), var.vms[each.key].os)
      error_message = "Unsupported OS profile."
    }

    precondition {
      condition     = contains(keys(var.disk_classes), var.vms[each.key].disks.root.class)
      error_message = "Unsupported disk class."
    }
    precondition {
      condition     = contains(local.cluster_online_nodes, each.value.node_name)
      error_message = "Invalid placement node for ${each.key}. The node must exist in the Proxmox cluster."
    }

    precondition {
      condition = alltrue([
        for node, priority in each.value.ha.node_affinity.nodes :
        contains(local.cluster_online_nodes, node)
      ])

      error_message = "Invalid HA node-affinity rule for ${each.key}. All affinity nodes must exist in the Proxmox cluster."
    }

    precondition {
      condition = (
        !each.value.ha.node_affinity.enabled
        || each.value.ha.enabled
      )

      error_message = "HA node-affinity for ${each.key} requires placement.ha.enabled = true."
    }
  }
}

resource "proxmox_haresource" "this" {
  for_each = local.ha_vms

  resource_id  = "vm:${proxmox_virtual_environment_vm.this[each.key].vm_id}"
  state        = each.value.ha.state
  max_restart  = each.value.ha.max_restart
  max_relocate = each.value.ha.max_relocate
  failback     = each.value.ha.failback
  comment      = "Managed by Terraform"
}

resource "proxmox_harule" "node_affinity" {
  for_each = local.ha_node_affinity_rules


  rule    = "tf-${each.key}-node-affinity"
  type    = "node-affinity"
  comment = "Node affinity rule for ${each.key}; managed by Terraform"

  resources = [
    "vm:${proxmox_virtual_environment_vm.this[each.key].vm_id}"
  ]

  nodes  = each.value.ha.node_affinity.nodes
  strict = each.value.ha.node_affinity.strict

  depends_on = [
    proxmox_haresource.this
  ]
}

resource "proxmox_harule" "resource_affinity" {
  for_each = local.enabled_ha_resource_rules
  rule   = "tf-${each.key}"
  type    = each.value.type=="resource-affinity"
  affinity = each.value.type =="resource-affinity"? "positive":"negative"
  strict  = try(each.value.strict, false)
  comment = try(each.value.comment, "Resource affinity rule ${each.key}; managed by Terraform")

  resources = [
    for vm_name in each.value.resources :
    "vm:${proxmox_virtual_environment_vm.this[vm_name].vm_id}"
  ]

  depends_on = [
    proxmox_haresource.this
  ]

  lifecycle {
    precondition {
      condition = alltrue([
        for vm_name in each.value.resources :
        contains(keys(proxmox_virtual_environment_vm.this), vm_name)
      ])

      error_message = "HA resource rule ${each.key} references a VM name that is not managed by this module."
    }

    precondition {
      condition = alltrue([
        for vm_name in each.value.resources :
        contains(keys(proxmox_haresource.this), vm_name)
      ])

      error_message = "HA resource rule ${each.key} references a VM that is not HA-enabled. Enable placement.ha.enabled for every VM in the rule."
    }
    precondition {
  condition = alltrue([
    for vm_name in each.value.resources :
    length(local.normalized_vms[vm_name].ha.node_affinity.nodes) <= 1
  ])

  error_message = "HA resource-affinity rules cannot be combined with multi-node priority node-affinity. Use at most one node in placement.ha.node_affinity.nodes for every VM in this resource rule."
}
  }
}
