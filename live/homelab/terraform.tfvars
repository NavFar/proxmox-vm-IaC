vms = {
  test-01 = {
    role        = "test"
    environment = "lab"
    size        = "medium"
    os          = "debian-13"

    placement = {
      policy = "preferred_node"
      node   = "tyrant"
    }

    network = {
      primary = {
        bridge = "vmbr0"
        ipv4 = {
          address = "172.16.10.115/24"
          gateway = "172.16.10.1"
        }
      }
    }

    disks = {
      root = {
        size_gb = 40
        class   = "fast"
      }
    }

    tags = ["infra"]
  }
test-02 = {
    role        = "test"
    environment = "lab"
    size        = "medium"
    os          = "debian-13"

    placement = {
      policy = "preferred_node"
      node   = "havoc"
    }

    network = {
      primary = {
        bridge = "vmbr0"
        ipv4 = {
          address = "dhcp"
        }
      }
    }

    disks = {
      root = {
        size_gb = 40
        class   = "fast"
      }
    }

    tags = ["infra"]
  }
}
user_info = {
  username    = "navidfarahmand"
  public_keys = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDf462QRz8CNGV2a/5l79EUmEYObxEAeaI8dm0I+Eo9GsYqv3edUVXkAGapJ0HrvZv3k6pxLDeRcpJN9FsQBm1I9N/VqkziGva7edvTDRtQU6Vr4nbEY0DL4lDuf1vB48C/aQ1zBekv5vkM3SjuRIk4JxbTOEmk36Q+ShgEYnWkrW0AZAWQVIL4rf8khQZLeoD2drOCBypER2bRWAPfhg0dEGxy+EsPeYybQQo1yNmvN82ony/eMCtSSRFaGRkJVNakMl8TQ9WWbayCkiGh/9GMh4liR/5+SA9prh6f3OpcQ2xflXlKf6xcZSaarbQ+Xag67CZNlGV4oAv8BrBZniq3Eo/EbzV4L9AO0xYSzdl8MQ2Mj6DA7hA9jyBAA3wRviJWrAfT5fVfXkgDZRTdyYjz4r++zKXYO5poD9IZ91f1VnRlAtpPKvPosQWTBn2Wyawd+5Wy/UlMIHPvU1H5TMSFnJF3oN8MmK+i8OZSpx5heNgSMbPZCWojqQ/r2vu8jW0= navidfarahmand@arch-legion"]
}
