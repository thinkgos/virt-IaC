terraform {
  required_providers {
    # https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = ">= 0.8.3"
    }
  }
}
provider "libvirt" {
  uri = "qemu:///system"
}

# resource "libvirt_pool" "ubuntu" {
#   name = "ubuntu"
#   type = "dir"
#   target {
#     path = "/var/lib/libvirt/images"
#   }
# }

# We fetch the latest ubuntu release image from their mirrors
resource "libvirt_volume" "ubuntu-qcow2" {
  name = "ubuntu-qcow2"
  pool = "default" # libvirt_pool.ubuntu.name
  # source = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  source = "/mms/CloudImages/noble-server-cloudimg-amd64.img"
  format = "qcow2"
}

data "template_file" "user_data" {
  template = file("${path.module}/cloud-init/user_data")
}

data "template_file" "meta_data" {
  template = file("${path.module}/cloud-init/meta_data")
}

data "template_file" "network_config" {
  template = file("${path.module}/cloud-init/network_config")
}

# for more info about paramater check this out
# https://github.com/dmacvicar/terraform-provider-libvirt/blob/master/website/docs/r/cloudinit.html.markdown
# Use CloudInit to add our ssh-key to the instance
# you can add also meta_data field
resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit.iso" # libvirt_pool.ubuntu.name
  pool           = "default"
  user_data      = data.template_file.user_data.rendered
  meta_data      = data.template_file.meta_data.rendered
  network_config = data.template_file.network_config.rendered
}

# Create the machine
resource "libvirt_domain" "domain-ubuntu" {
  name   = "tf-ubuntu"
  memory = "2048"
  vcpu   = 2

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
    network_name = "default"
  }

  # IMPORTANT: this is a known bug on cloud images, since they expect a console
  # we need to pass it
  # https://bugs.launchpad.net/cloud-images/+bug/1573095
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.ubuntu-qcow2.id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}
