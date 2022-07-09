variable "kubernetes_nodes" {
  type = list(object({
    hostname = string
    ip       = string
    gw       = string
    target   = string
    vmid     = number
  }))
  default = [
    {
      gw       = "10.0.6.1"
      hostname = "k8s-node-1"
      ip       = "10.0.6.32"
      target   = "apollo"
      vmid     = 101
    }
  ]
}

variable "node_options" {
  type = object({
    bridge       = string
    cores        = number
    diskLocation = string
    diskSize     = string
    image        = string
    memory       = number
  })
  default = {
    bridge       = "vmbr1"
    cores        = 4
    diskLocation = "local-lvm"
    diskSize     = "25G"
    image        = "ubuntu-jammy"
    memory       = 4096
  }
}

variable "pve_host" {
  type = object({
    ip       = string
    password = string
    username = string
  })
  default = {
    ip       = "10.0.0.8"
    password = "proxmox"
    username = "root@pam"
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
  target_node = var.kubernetes_nodes[count.index].target
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
