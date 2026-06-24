provider "proxmox" {
  endpoint  = var.proxmox_info.endpoint
  insecure  = var.proxmox_info.insecure
  api_token = var.proxmox_info.api_token
}
