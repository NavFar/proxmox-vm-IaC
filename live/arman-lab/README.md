# Homelab Proxmox VM Fleet

Terraform live environment for the homelab Proxmox cluster.

This directory defines the actual VM fleet, profiles, HA placement rules, and provider connection settings for the homelab environment.

## Directory layout

```text
live/homelab/
├── main.tf
├── outputs.tf
├── profile.tf
├── providers.tf
├── variables.tf
├── versions.tf
├── 10-vms.auto.tfvars
├── 20-ha_rules.auto.tfvars
└── secrets.auto.tfvars
```

## File responsibilities

### `main.tf`

Wires this live environment to the reusable module:

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

### `profile.tf`

Contains environment-specific profiles and defaults:

* `default_node`
* `size_profiles`
* `os_profiles`
* `disk_classes`

These are not operator inputs. They are environment configuration.

### `10-vms.auto.tfvars`

Contains VM intent.

Use this file for:

* VM names
* roles
* environments
* selected size profile
* selected OS profile
* placement
* HA enablement
* node-affinity
* network settings
* disk sizing
* tags

Example:

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

### `20-ha_rules.auto.tfvars`

Contains HA relationship rules between VMs.

Use this file for cross-VM rules, not per-VM settings.

Example:

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

Supported rule types:

```text
resource-affinity
resource-anti-affinity
```

The `resources` list uses VM names from the `vms` map, not Proxmox VM IDs.

### `secrets.auto.tfvars`

Local-only secrets.

This file should not be committed.

Example:

```hcl
proxmox_info = {
  endpoint  = "https://proxmox.example.local:8006/"
  insecure  = true
  api_token = "USER@REALM!TOKEN=SECRET"
}

users_info = [
  {
    username    = "debian"
    public_keys = ["ssh-ed25519 ..."]
  }
]
```

## Terraform commands

Run all commands from this directory:

```bash
cd live/homelab
```

Initialize:

```bash
terraform init
```

Format:

```bash
terraform fmt -recursive
```

Validate:

```bash
terraform validate
```

Plan:

```bash
terraform plan
```

Apply:

```bash
terraform apply
```

Show outputs:

```bash
terraform output
terraform output vms
terraform output resource_affinity
```

## Important rules

### Do not split the same variable across multiple tfvars files

Terraform does not deep-merge maps from multiple `.tfvars` files.

This is good:

```text
10-vms.auto.tfvars       -> vms = {...}
20-ha_rules.auto.tfvars  -> ha_resource_rules = {...}
```

This is bad:

```text
10-test01.auto.tfvars -> vms = {...}
11-test02.auto.tfvars -> vms = {...}
```

The later value replaces the earlier value.

### Keep profiles in `profile.tf`

Profiles are environment configuration, not operator input.

Keep these in `profile.tf`:

* size profiles
* OS/template profiles
* disk classes
* default node

Keep these in `.auto.tfvars`:

* VM definitions
* HA relationship rules
* secrets

### HA relationship rules require HA-enabled VMs

Every VM referenced in `ha_resource_rules.resources` must have:

```hcl
placement = {
  ha = {
    enabled = true
  }
}
```

### Avoid resource rules with multi-node priority node-affinity

For VMs participating in resource-affinity or anti-affinity rules, use at most one node in `placement.ha.node_affinity.nodes`.

Good:

```hcl
nodes = {
  tyrant = 100
}
```

Avoid:

```hcl
nodes = {
  tyrant = 100
  havoc  = 50
}
```

This avoids conflicting scheduler intent between node preference and resource relationship rules.

