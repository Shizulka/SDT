terraform {
  required_providers {
    virtualbox = {
      source = "terra-farm/virtualbox"
      version = "0.2.2-alpha.1"
    }
  }
}

provider "virtualbox" {}

resource "virtualbox_vm" "worker" {
  name   = "worker-vm"
  image  = "https://app.vagrantup.com/ubuntu/boxes/noble64/versions/0.0.1/providers/virtualbox.box"
  cpus   = 2
  memory = "2048 mib"

  network_adapter {
    type           = "hostonly"
    host_interface = "vboxnet0"
  }
}

resource "virtualbox_vm" "db" {
  name   = "db-vm"
  image  = "https://app.vagrantup.com/ubuntu/boxes/noble64/versions/0.0.1/providers/virtualbox.box"
  cpus   = 2
  memory = "2048 mib"

  network_adapter {
    type           = "hostonly"
    host_interface = "vboxnet0"
  }
}
