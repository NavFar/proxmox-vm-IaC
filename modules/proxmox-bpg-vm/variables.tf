variable "vms" {
  description = "Business-level VM definitions."
  type = map(object({
    role        = string
    environment = string
    size        = string
    os          = string

    placement = object({
      policy = string
      node   = optional(string)
    })

    network = object({
      primary = object({
        bridge = string
        vlan   = optional(number)
        ipv4 = object({
          address = string
          gateway = optional(string)

        })
      })
    })

    disks = object({
      root = object({
        size_gb = number
        class   = string
      })
    })

    tags = optional(list(string), [])
  }))

  validation {
    condition = alltrue([
      for name, vm in var.vms :
      contains(keys(var.size_profiles), vm.size)
    ])

    error_message = "VM size must exist in size_profiles."
  }

  validation {
    condition = alltrue([
      for name, vm in var.vms :
      contains(["preferred_node", "spread"], vm.placement.policy)
    ])
    error_message = "placement.policy must be preferred_node or spread."
  }

  validation {
    condition = alltrue([
      for name, vm in var.vms :
      vm.placement.policy != "preferred_node" || try(vm.placement.node, null) != null
    ])
    error_message = "placement.node is required when placement.policy is preferred_node."
  }
}
variable "default_node" {
  type        = string
  description = "Fallback Proxmox node when placement policy does not specify a node."
}
variable "size_profiles" {
  type = map(object({
    cpu_cores = number
    memory_mb = number
  }))
  description = "Size Profile for VMs to be created based of"
  validation {
    condition = alltrue([
      for profile in values(var.size_profiles) :
      profile.cpu_cores >= 1 && profile.memory_mb >= 512
    ])

    error_message = "Each size profile must have at least 1 CPU core and at least 512 MB memory."
  }

  validation {
    condition = alltrue([
      for profile in values(var.size_profiles) :
      profile.memory_mb % 128 == 0
    ])

    error_message = "memory_mb must be divisible by 128."
  }
}

variable "os_profiles" {
  description = "template ID and user information to create VM from"
  type = map(object({
    template_id = number
    username    = string
    public_keys = list(string)
  }))
}


variable "disk_classes" {
  description = "type of storage for each VM"
  type = map(object({
    datastore_id = string
    interface    = string
  }))
  default = {
    fast = {
      datastore_id = "local-zfs"
      interface    = "scsi0"
    }

    bulk = {
      datastore_id = "hdd-zfs"
      interface    = "scsi0"
    }
  }

}
