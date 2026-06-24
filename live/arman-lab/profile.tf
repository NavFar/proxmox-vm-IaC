locals {
  default_node = "pveauto1"
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
    ubuntu-2024 = {
      template_id   = 9000
      template_node = "pveauto1"
      username      = var.users_info[0].username
      public_keys   = var.users_info[0].public_keys
    }
  }
  disk_classes = {
    local_zfs = {
      datastore_id = "zfscluster"
      interface    = "scsi0"
    }
  }
}
