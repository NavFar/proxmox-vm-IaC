vms = {
  test-01 = {
    role        = "test"
    environment = "lab"
    size        = "medium"
    os          = "debian-13"

    placement = {
      policy = "preferred_node"
      node   = "tyrant"
      ha = {
        enabled = true
      }
    }

    network = {
      primary = {
        bridge = "vmbr0"
        ipv4 = {
          address = "172.16.10.115/24"
          gateway = "172.16.10.1"
        }
      }
    }

    disks = {
      root = {
        size_gb = 40
        class   = "fast"
      }
    }

    tags = ["infra"]
  }
  test-02 = {
    role        = "test"
    environment = "lab"
    size        = "medium"
    os          = "debian-13"

    placement = {
      policy = "preferred_node"
      node   = "havoc"
      ha = {
        enabled = true
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
        size_gb = 40
        class   = "fast"
      }
    }

    tags = ["infra"]
  }
}
