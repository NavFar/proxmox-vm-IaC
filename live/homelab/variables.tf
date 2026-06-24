variable "vms" {
  type = any
}
variable "users_info" {
  description = "provisioner users info for VMs"
  type = list(object({
    username    = string
    public_keys = list(string)
  }))
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
