resource "proxmox_virtual_environment_vm" "ubuntu_test" {
  name      = "ubuntu-terraform"
  node_name = "pve01"
  vm_id     = 103

  cpu {
    cores = 1
  }

  memory {
    dedicated = 1024
  }

  network_device {
    bridge = "vmbr0"
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 8
  }

  cdrom {
    file_id   = "local:iso/ubuntu-24.04.4-live-server-amd64.iso"
    interface = "ide2"
  }

  boot_order = ["ide2", "scsi0"]
}
