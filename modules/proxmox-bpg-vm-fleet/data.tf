data "proxmox_virtual_environment_nodes" "cluster" {}
data "proxmox_datastores" "node" {
  for_each = local.storage_check_nodes

  node_name = each.key

  filters = {
    content_types = ["images"]
  }
}
