vms = {
  local-ha-01 = {
    role        = "test"
    environment = "lab"
    size        = "medium"
    os          = "ubuntu-2024"

    placement = {
      policy = "preferred_node"
      node   = "pveauto1"

      ha = {
        enabled      = true
        state        = "started"
        max_restart  = 3
        max_relocate = 2
        failback     = false

        replication = {
          enabled  = true
          schedule = "*/5"
          rate     = null
        }

        node_affinity = {
          enabled = true
          strict  = false

          nodes = {
            pveauto1 = 100
            pveauto2 = 50
          }
        }
      }
    }

    network = {
      primary = {
        bridge = "vmbr0"

        ipv4 = {
          address = "dhcp"
        }
      }
    }

    disks = {
      root = {
        size_gb = 32
        class   = "local_zfs"
      }
    }

    tags = [
      "test",
      "ha",
      "replicated",
      "local-storage",
    ]
  }
}
