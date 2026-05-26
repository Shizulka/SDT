terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.8.3"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_network" "lab4_network" {
  name      = "lab4-network"
  mode      = "nat"
  domain    = "lab4.local"
  addresses = ["192.168.100.0/24"]

  dhcp {
    enabled = true
  }
}

resource "libvirt_volume" "worker_disk" {
  name   = "worker-vm.qcow2"
  pool   = "default"
  source = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  format = "qcow2"
}

resource "libvirt_volume" "db_disk" {
  name   = "db-vm.qcow2"
  pool   = "default"
  source = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  format = "qcow2"
}

resource "libvirt_cloudinit_disk" "worker_cloudinit" {
  name = "worker-cloudinit.iso"
  pool = "default"

  user_data = templatefile("${path.module}/cloud-init.yml", {
    hostname = "worker-vm"
  })
}

resource "libvirt_cloudinit_disk" "db_cloudinit" {
  name = "db-cloudinit.iso"
  pool = "default"

  user_data = templatefile("${path.module}/cloud-init.yml", {
    hostname = "db-vm"
  })
}

resource "libvirt_domain" "worker" {
  name   = "worker-vm"
  memory = 2048
  vcpu   = 2

  cloudinit = libvirt_cloudinit_disk.worker_cloudinit.id

  network_interface {
    network_id     = libvirt_network.lab4_network.id
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.worker_disk.id
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }
}

resource "libvirt_domain" "db" {
  name   = "db-vm"
  memory = 2048
  vcpu   = 2

  cloudinit = libvirt_cloudinit_disk.db_cloudinit.id

  network_interface {
    network_id     = libvirt_network.lab4_network.id
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.db_disk.id
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }
}

output "worker_ip" {
  value = libvirt_domain.worker.network_interface[0].addresses[0]
}

output "db_ip" {
  value = libvirt_domain.db.network_interface[0].addresses[0]
}
