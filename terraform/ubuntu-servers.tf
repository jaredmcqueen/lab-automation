variable "vm_count" {
  type    = number
  default = 1
}

variable "project_prefix" {
  type    = string
  default = "dev-vm"
}

# will result in 10.0.6.31, 32, 33, etc.
variable "ip_address_prefix" {
  type    = string
  default = "10.0.6.3"
}

variable "ip_address_gateway" {
  type    = string
  default = "10.0.6.1"
}

variable "pve_username" {
  type    = string
  default = "root@pam"
}

variable "pve_password" {
  type = string
}

variable "pve_ip" {
  type    = string
  default = "10.0.0.7"
}

variable "pve_hostname" {
  type    = string
  default = "apollo"
}

variable "memory" {
  type    = number
  default = 4096
}

variable "cores" {
  type    = number
  default = 4
}

variable "diskSize" {
  type    = string
  default = "15G"
}

variable "diskLocation" {
  type    = string
  default = "local-lvm"
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
  pm_api_url      = "https://${var.pve_ip}:8006/api2/json"
  pm_user         = var.pve_username
  pm_password     = var.pve_password
}

/* user-data */
data "template_file" "user_data" {
  count    = var.vm_count
  template = file("${path.module}/ubuntu.cloud_config")
  vars = {
    pubkey   = file("~/.ssh/id_rsa.pub")
    hostname = "${var.project_prefix}-${count.index}"
    password = var.pve_password
  }
}

resource "local_file" "cloud_init_user_data_file" {
  count    = var.vm_count
  content  = data.template_file.user_data[count.index].rendered
  filename = "${path.module}/files/${var.project_prefix}_user_data_${count.index}.yml"
}

resource "null_resource" "cloud_init_config_files" {
  count = var.vm_count
  connection {
    type        = "ssh"
    host        = var.pve_ip
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "file" {
    source      = local_file.cloud_init_user_data_file[count.index].filename
    destination = "/var/lib/vz/snippets/${var.project_prefix}_user_data-${count.index}.yml"
  }
}

resource "proxmox_vm_qemu" "proxmox_vm" {
  depends_on = [
    null_resource.cloud_init_config_files,
  ]

  count       = var.vm_count
  name        = "${var.project_prefix}-${count.index}"
  agent       = 1
  vmid        = "30${count.index}"
  target_node = var.pve_hostname
  clone       = "ubuntu-cloudinit"
  full_clone  = true
  os_type     = "l26"
  # os_type     = "cloud-init"
  cores       = var.cores
  sockets     = "1"
  cpu         = "host"
  memory      = var.memory
  scsihw      = "virtio-scsi-pci"

  disk {
    type     = "virtio"
    storage  = var.diskLocation
    size     = var.diskSize
    discard  = "on"
  }

  # vmbr1 is my VM network in proxmox 
  network {
    model  = "virtio"
    bridge = "vmbr6"
  }

  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  # Cloud Init Settings
  ipconfig0               = "ip=${var.ip_address_prefix}${count.index + 1}/24,gw=${var.ip_address_gateway}"
  sshkeys                 = file("~/.ssh/id_rsa.pub")
  cicustom                = "user=local:snippets/${var.project_prefix}_user_data-${count.index}.yml"
  cloudinit_cdrom_storage = "local-lvm"
}
