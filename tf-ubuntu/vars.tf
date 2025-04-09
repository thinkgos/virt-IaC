variable "base_volume_config" {
  description = "配置基础卷"
  type = object({
    source =  string
    format = string
  })
  default = {
    # source = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
    source = "/mms/CloudImages/noble-server-cloudimg-amd64.img"
    format = "qcow2"
  }
}

variable "main_volume_config" {
  description = "配置主卷"
  type = object({
    size = number
  })
  default = {
    size = 20 * 1024 * 1024 * 1024 # 20g
  }
}

variable "vm_config" {
    description = "虚拟机domain配置"
    type = object({
      name = string
      vcpu = number
      memory = number
    })
    default = {
      name = "vm-ubuntu"
      vcpu = 2
      memory = "2048"
    }
}