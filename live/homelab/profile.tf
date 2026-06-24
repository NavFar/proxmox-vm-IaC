locals {
default_node = "tyrant"
size_profiles = {
    tiny = {
      cpu_cores = 1
      memory_mb = 1024
    }

    small = {
      cpu_cores = 2
      memory_mb = 2048
    }

    medium = {
      cpu_cores = 4
      memory_mb = 8192
    }

    large = {
      cpu_cores = 8
      memory_mb = 16384
    }
  }
  os_profiles = {
    debian-13 = {
      template_id   = 9000
      template_node = "tyrant"
      username      = var.users_info[0].username
      public_keys   = var.users_info[0].public_keys
    }
    ubuntu-2404 = {
      template_id   = 9001
      template_node = "tyrant"
      username      = var.users_info[0].username
      public_keys   = var.users_info[0].public_keys
    }
  }
  disk_classes = {
    fast = {
      datastore_id = "homelab-iscsi-lvm"
      interface    = "scsi0"
    }
  }
}
