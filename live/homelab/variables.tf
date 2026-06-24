variable "default_node" {
  description = "defacto node to put new VMs on"
  type = string
}
variable "vms" {
  type = any
}
variable "user_info" {
  description = "provisioner user info for VMs"
  type = object({
    username    = string
    public_keys = list(string)
  })
}
variable "proxmox_info" {
  description = "Proxmox connection info"
  sensitive   = true
  type = object({
    endpoint  = string
    insecure  = bool
    api_token = string
  })
}
variable "ha_resource_rules" {
  description = "HA resource affinity and anti-affinity rules between VMs."
  type        = any
  default     = {}
}
