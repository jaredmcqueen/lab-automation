wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
virt-customize -a jammy-server-cloudimg-amd64.img --install qemu-guest-agent
qm destroy 9000
qm create 9000 --name ubuntu-jammy --memory 1024 --net0 virtio,bridge=vmbr0 --cores 1 --sockets 1
qm importdisk 9000 jammy-server-cloudimg-amd64.img local-lvm
qm set 9000 --scsihw virtio-scsi-pci --virtio0 local-lvm:vm-9000-disk-0
qm set 9000 --serial0 socket
qm set 9000 --boot c --bootdisk virtio0
qm set 9000 --agent enabled=1
qm set 9000 --hotplug disk,network,usb
qm set 9000 --vcpus 1
qm set 9000 --vga qxl
qm set 9000 --ide2 local-lvm:cloudinit
qm template 9000
