variable "kubernetes_nodes" {
  type = list(object({
    hostname = string
    ip       = string
    gw       = string
    vmid     = number
  }))
  default = [
    {
      hostname = "k8s-node-1"
      ip       = "10.0.6.32"
      gw       = "10.0.6.1"
      vmid     = 101
    }
  ]
}

variable "node_options" {
  type = object({
    image        = string
    memory       = number
    cores        = number
    diskSize     = string
    diskLocation = string
    bridge       = string
  })
  default = {
    image        = "ubuntu-jammy"
    memory       = 4096
    cores        = 4
    diskSize     = "25G"
    diskLocation = "local-lvm"
    bridge       = "vmbr1"
  }
}

variable "pve_host" {
  type = object({
    username = string
    password = string
    ip       = string
    hostname = string
  })
  default = {
    username = "root@pam"
    password = "proxmox"
    ip       = "10.0.0.8"
    hostname = "apollo"
  }
}

terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
    }
  }
}

provider "proxmox" {
  pm_tls_insecure = true
  pm_api_url      = "https://${var.pve_host.ip}:8006/api2/json"
  pm_user         = var.pve_host.username
  pm_password     = var.pve_host.password
}

resource "proxmox_vm_qemu" "proxmox_vm" {
  count       = length(var.kubernetes_nodes)
  name        = var.kubernetes_nodes[count.index].hostname
  agent       = 1
  vmid        = var.kubernetes_nodes[count.index].vmid
  target_node = var.pve_host.hostname
  clone       = var.node_options.image
  full_clone  = true
  os_type     = "cloud-init"
  cores       = var.node_options.cores
  sockets     = "1"
  cpu         = "host"
  memory      = var.node_options.memory
  scsihw      = "virtio-scsi-pci"
  bootdisk    = "scsi0"

  disk {
    #    slot     = 0
    type    = "virtio"
    storage = var.node_options.diskLocation
    size    = var.node_options.diskSize
    discard = "on"
  }

  network {
    model  = "virtio"
    bridge = var.node_options.bridge
  }

  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  # Cloud Init Settings
  ipconfig0 = "ip=${var.kubernetes_nodes[count.index].ip}/24,gw=${var.kubernetes_nodes[count.index].gw}"
  sshkeys   = file("~/.ssh/id_rsa.pub")
}
