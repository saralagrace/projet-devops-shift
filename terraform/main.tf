terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.120.0"
    }
  }
}

provider "proxmox" {
  endpoint = "https://10.0.0.10:8006/"
  insecure = true
}
