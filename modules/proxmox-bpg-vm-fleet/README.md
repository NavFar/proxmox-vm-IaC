# proxmox-bpg-vm-fleet

Reusable Terraform module for managing a fleet of Proxmox VMs using the BPG Proxmox provider.

The module accepts business-level VM definitions and translates them into Proxmox resources:

* `proxmox_virtual_environment_vm`
* `proxmox_haresource`
* `proxmox_harule` for node-affinity
* `proxmox_harule` for resource-affinity / anti-affinity

It also reads Proxmox cluster node information and validates placement and HA node-affinity rules against the cluster.

## Responsibilities

This module owns the Proxmox-specific implementation for:

* VM creation
* full cloning from templates
* source template node selection
* target node placement
* cloud-init initialization
* root disk creation
* network device creation
* HA resource registration
* node-affinity HA rules
* resource-affinity / anti-affinity HA rules
* cluster node discovery
* placement validation

## Inputs

### `vms`

Business-level VM definitions.

Each VM supports:

```hcl
vms = {
  test-01 = {
    role        = "test"
    environment = "lab"
    size        = "small"
    os          = "debian-13"

    placement = {
      policy = "preferred_node"
      node   = "tyrant"

      ha = {
        enabled      = true
        state        = "started"
        max_restart  = 3
        max_relocate = 2
        failback     = false

        node_affinity = {
          enabled = true
          strict  = false

          nodes = {
            tyrant = 100
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
        class   = "fast"
      }
    }

    tags = ["test"]
  }
}
```

### `default_node`

Fallback node used when placement policy does not provide a specific target.

```hcl
default_node = "tyrant"
```

### `size_profiles`

Named CPU and memory profiles.

```hcl
size_profiles = {
  small = {
    cpu_cores = 2
    memory_mb = 2048
  }
}
```

VM definitions reference these by name:

```hcl
size = "small"
```

### `os_profiles`

Named OS/template profiles.

```hcl
os_profiles = {
  debian-13 = {
    template_id   = 9000
    template_node = "tyrant"
    username      = "debian"
    public_keys   = ["ssh-ed25519 ..."]
  }
}
```

`template_node` is the source node where the Proxmox template VM config exists. This is separate from the target VM placement node.

### `disk_classes`

Named storage classes for root disks.

```hcl
disk_classes = {
  fast = {
    datastore_id = "homelab-iscsi-lvm"
    interface    = "scsi0"
  }
}
```

VM definitions reference these by name:

```hcl
class = "fast"
```

### `ha_resource_rules`

Cross-VM HA relationship rules.

```hcl
ha_resource_rules = {
  separate_test_pair = {
    enabled = true
    type    = "resource-anti-affinity"
    strict  = false

    resources = [
      "test-01",
      "test-02",
    ]

    comment = "Prefer test-01 and test-02 to run separately"
  }
}
```

Supported user-facing types:

```text
resource-affinity
resource-anti-affinity
```

The module translates these to the provider-level Proxmox HA rule representation.

## Placement model

The module separates initial VM creation placement from HA scheduling rules.

```text
placement.node
  Initial Proxmox node used when creating the VM.

placement.ha.node_affinity
  Proxmox HA node-affinity rule for where HA should prefer or force the VM to run.
```

Example:

```hcl
placement = {
  policy = "preferred_node"
  node   = "tyrant"

  ha = {
    enabled = true

    node_affinity = {
      enabled = true
      strict  = false

      nodes = {
        tyrant = 100
      }
    }
  }
}
```

## HA rules

### HA registration

When `placement.ha.enabled = true`, the module creates a Proxmox HA resource for the VM.

### Node affinity

When `placement.ha.node_affinity.enabled = true`, the module creates a node-affinity HA rule for that VM.

Node weights use this shape:

```hcl
nodes = {
  tyrant = 100
  havoc  = 50
}
```

### Resource affinity and anti-affinity

Resource rules are defined separately from individual VMs because they describe relationships between multiple VMs.

Example anti-affinity:

```hcl
ha_resource_rules = {
  separate_test_pair = {
    enabled = true
    type    = "resource-anti-affinity"
    strict  = false
    resources = ["test-01", "test-02"]
  }
}
```

The VM names in `resources` must match keys from the `vms` map.

## Guardrails

The module validates several conditions:

* VM size must exist in `size_profiles`.
* Placement policy must be supported.
* `placement.node` is required for `preferred_node`.
* HA state must be one of `started`, `stopped`, `disabled`, or `ignored`.
* Node-affinity must contain at least one node when enabled.
* Node-affinity priorities must be non-negative.
* Placement and affinity nodes must exist in the Proxmox cluster.
* Node-affinity requires HA to be enabled.
* Resource-affinity rules must reference VMs managed by this module.
* Resource-affinity rules must reference HA-enabled VMs.
* Resource-affinity rules cannot be combined with multi-node priority node-affinity for the same VMs.

## Outputs

### `vms`

Created VM details indexed by VM name.

Includes:

* VM ID
* name
* node name
* desired IPv4
* discovered IPv4 addresses
* primary IPv4
* HA enabled flag
* HA state
* node-affinity settings

### `ha_resource_rules`

Created resource-affinity / anti-affinity rules.

Includes:

* rule ID
* rule name
* Proxmox type
* affinity value
* strict flag
* disabled flag
* comment
* Proxmox resource IDs
* input VM names

## Usage

```hcl
module "proxmox_vm_fleet" {
  source = "../../modules/proxmox-bpg-vm-fleet"

  default_node      = local.default_node
  vms               = var.vms
  size_profiles     = local.size_profiles
  os_profiles       = local.os_profiles
  disk_classes      = local.disk_classes
  ha_resource_rules = var.ha_resource_rules
}
```

## Operational notes

HA can move VMs between nodes outside Terraform. The module ignores VM `node_name` drift to avoid constant state churn after HA migration.

The Proxmox template source node and target VM node are intentionally separate. Shared storage does not mean the template VM config exists on every node.

