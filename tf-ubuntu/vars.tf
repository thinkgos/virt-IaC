variable "vm_config" {
  description = "虚拟机配置"
  type = object({
    base_volume = object({
      source = string
      format = string
    })
    main_volume = object({
      size = number
    })
    domain = object({
      name   = string
      vcpu   = number
      memory = number
    })
  })

  default = {
    # 基础卷
    base_volume = {
      # source = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
      source = "/mms/CloudImages/noble-server-cloudimg-amd64.img"
      format = "qcow2"
    }
    // 主卷
    main_volume = {
      size = 1024 * 1024 * 1024 * 20 # 20g
    }
    # 域
    domain = {
      name   = "vm-ubuntu"
      vcpu   = 2
      memory = "2048"
    }
  }
}