# Proxmox VM IaC

Terraform-based Infrastructure as Code for managing Proxmox VM fleets.

This repository separates high-level VM intent from the Proxmox/BPG provider implementation. The live environment describes what VMs should exist, where they should run, and what HA rules should apply. The reusable module translates that intent into Proxmox VM, HA resource, node-affinity, and resource-affinity resources.

## Repository layout

```text
.
├── live/
│   └── homelab/
│       ├── main.tf
│       ├── profile.tf
│       ├── providers.tf
│       ├── variables.tf
│       ├── versions.tf
│       ├── outputs.tf
│       ├── 10-vms.auto.tfvars
│       ├── 20-ha_rules.auto.tfvars
│       └── secrets.auto.tfvars
└── modules/
    └── proxmox-bpg-vm-fleet/
        ├── data.tf
        ├── locals.tf
        ├── main.tf
        ├── outputs.tf
        ├── variables.tf
        └── versions.tf
```

## Design model

The repository has two layers:

```text
live/homelab
  Environment-specific intent:
  - VM definitions
  - HA relationship rules
  - size profiles
  - OS/template profiles
  - disk classes
  - provider connection settings

modules/proxmox-bpg-vm-fleet
  Provider-specific implementation:
  - Proxmox VM creation
  - clone source node handling
  - cluster node discovery
  - placement validation
  - HA registration
  - node-affinity rules
  - resource-affinity / anti-affinity rules
```

The live layer should stay readable and close to business intent. The module should contain the Proxmox-specific translation logic.

## Main concepts

### VM intent

VMs are defined as business-level objects. A VM definition includes:

* role
* environment
* size profile
* OS/template profile
* placement policy
* network settings
* root disk class
* optional tags
* optional HA settings

### Profiles

Profiles live in `live/homelab/profile.tf`.

They describe environment-level defaults and mappings:

* `default_node`
* `size_profiles`
* `os_profiles`
* `disk_classes`

### HA rules

HA relationship rules live in `live/homelab/20-ha_rules.auto.tfvars`.

The user-facing syntax supports Kubernetes-style naming:

```hcl
type = "resource-affinity"
```

or:

```hcl
type = "resource-anti-affinity"
```

The module translates this into the Proxmox/BPG HA rule format.

## Typical workflow

From the live environment directory:

```bash
cd live/homelab
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

Inspect outputs:

```bash
terraform output
terraform output vms
terraform output resource_affinity
```

## Secrets

Secrets should not be committed.

Use:

```text
live/homelab/secrets.auto.tfvars
```

for local provider credentials.

Example shape:

```hcl
proxmox_info = {
  endpoint  = "https://proxmox.example.local:8006/"
  insecure  = true
  api_token = "USER@REALM!TOKEN=SECRET"
}
```

Ensure `secrets.auto.tfvars` is ignored by Git.

## Formatting

Run this before committing:

```bash
terraform fmt -recursive
```

Terraform does not require specific file names, but formatted multi-line HCL is required for readable diffs and code review.

## Notes

This repository is currently focused on Proxmox VMs using the BPG Proxmox provider. The abstraction is intentionally shaped so that most user-facing VM intent stays stable even if provider-specific implementation details change later.

