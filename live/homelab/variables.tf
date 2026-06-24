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
  sensitive = true
  type = object({
    endpoint  = string
    insecure  = bool
    api_token = string
  })
}
