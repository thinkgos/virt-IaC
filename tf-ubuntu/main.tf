# https://developer.hashicorp.com/terraform/tutorials/configuration-language
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

locals {
  name_prefix = "${var.vm_config.domain.name}-" # 命名前缀
}

# resource "libvirt_pool" "ubuntu" {
#   name = "ubuntu"
#   type = "dir"
#   target {
#     path = "/var/lib/libvirt/images"
#   }
# }

# fetch the latest ubuntu release image from their mirrors
resource "libvirt_volume" "base-volume" {
  name   = "${local.name_prefix}base-volume"
  pool   = "default"
  source = var.vm_config.base_volume.source
  format = var.vm_config.base_volume.format
}

resource "libvirt_volume" "main-volume" {
  name           = "${local.name_prefix}main-volume"
  pool           = libvirt_volume.base-volume.pool
  format         = libvirt_volume.base-volume.format
  base_volume_id = libvirt_volume.base-volume.id
  size           = var.vm_config.main_volume.size
}

# for more info about parameter check this out
# https://github.com/dmacvicar/terraform-provider-libvirt/blob/master/website/docs/r/cloudinit.html.markdown
resource "libvirt_cloudinit_disk" "seed-disk" {
  name           = "${local.name_prefix}seed.iso"
  pool           = libvirt_volume.base-volume.pool
  user_data      = file("cloud-init/user_data")      # cloud-init user data
  meta_data      = file("cloud-init/meta_data")      # cloud-init meta data
  network_config = file("cloud-init/network_config") # cloud-init network-config data
}

# Create the machine
resource "libvirt_domain" "vm-domain" {
  name   = var.vm_config.domain.name
  memory = var.vm_config.domain.memory
  vcpu   = var.vm_config.domain.vcpu

  cloudinit = libvirt_cloudinit_disk.seed-disk.id # attached as a CDROM

  disk {
    volume_id = libvirt_volume.main-volume.id
  }

  network_interface {
    network_name = "default"
  }

  graphics {
    type        = "spice"
    autoport    = true
    listen_type = "address"
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
}
