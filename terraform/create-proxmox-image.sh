wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
qm create 9000 -name ubuntu-cloudinit -memory 1024 -net0 virtio,bridge=vmbr0 -cores 1 -sockets 1
qm importdisk 9000 focal-server-cloudimg-amd64.img local-lvm
qm set 9000 -scsihw virtio-scsi-pci -virtio0 local-lvm:vm-9000-disk-0
qm set 9000 -serial0 socket
qm set 9000 -boot c -bootdisk virtio0
qm set 9000 -agent 1
qm set 9000 -hotplug disk,network,usb
qm set 9000 -vcpus 1
qm set 9000 -vga qxl
qm set 9000 -ide2 local-lvm:cloudinit
qm template 9000
