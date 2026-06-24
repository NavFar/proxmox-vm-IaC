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
      ha = optional(object({
        enabled      = optional(bool, false)
        state        = optional(string, "started")
        max_restart  = optional(number, 3)
        max_relocate = optional(number, 2)
        failback     = optional(bool, false)
        node_affinity = optional(object({
          enabled = optional(bool, false)
          strict  = optional(bool, false)
          nodes   = map(number)
          }), {
          enabled = false
          strict  = false
          nodes   = {}
        })

        }),
        {
          enabled      = false
          state        = "started"
          max_restart  = 3
          max_relocate = 2
          failback     = false
          node_affinity = {
            enabled = false
            strict  = false
            nodes   = {}
          }
        }
      )
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
  validation {
    condition = alltrue([
      for name, vm in var.vms :
      contains(["started", "stopped", "disabled", "ignored"], try(vm.placement.ha.state, "started"))
    ])

    error_message = "placement.ha.state must be one of: started, stopped, disabled, ignored."
  }
  validation {
    condition = alltrue([
      for name, vm in var.vms :
      !try(vm.placement.ha.node_affinity.enabled, false)
      || length(try(vm.placement.ha.node_affinity.nodes, {})) > 0
    ])

    error_message = "placement.ha.node_affinity.nodes must contain at least one node when node_affinity.enabled is true."
  }

  validation {
    condition = alltrue(flatten([
      for name, vm in var.vms : [
        for node, priority in try(vm.placement.ha.node_affinity.nodes, {}) :
        priority >= 0
      ]
    ]))

    error_message = "placement.ha.node_affinity.nodes priorities must be >= 0."
  }
}
variable "default_node" {
  type        = string
  description = "Fallback Proxmox node when placement policy does not specify a node."
  validation {
    condition = contains(local.cluster_online_nodes, var.default_node)
    error_message = "Default node should be one of alive and active nodes in cluster"
  }
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
    template_id   = number
    template_node = string
    username      = string
    public_keys   = list(string)
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

variable "ha_resource_rules" {
  description = "HA resource affinity and anti-affinity rules between VMs managed by this module."

  type = map(object({
    enabled   = optional(bool, true)
    type      = string
    strict    = optional(bool, false)
    resources = list(string)
    comment   = optional(string, null)
  }))

  default = {}

  validation {
    condition = alltrue([
      for name, rule in var.ha_resource_rules :
      contains(["resource-affinity", "resource-anti-affinity"], rule.type)
    ])

    error_message = "ha_resource_rules.type must be resource-affinity or resource-anti-affinity."
  }

  validation {
    condition = alltrue([
      for name, rule in var.ha_resource_rules :
      length(rule.resources) >= 2
    ])

    error_message = "ha_resource_rules.resources must contain at least two VM names."
  }
}
