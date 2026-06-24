resource "proxmox_virtual_environment_vm" "this" {
  for_each = local.normalized_vms

  name        = each.value.name
  description = each.value.description
  node_name   = each.value.node_name
  tags        = each.value.tags

  clone {
    node_name = each.value.template_node
    vm_id = each.value.template_id
    full  = true
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
    precondition {
      condition     = contains(keys(var.os_profiles), var.vms[each.key].os)
      error_message = "Unsupported OS profile."
    }

    precondition {
      condition     = contains(keys(var.disk_classes), var.vms[each.key].disks.root.class)
      error_message = "Unsupported disk class."
    }
  }
}
