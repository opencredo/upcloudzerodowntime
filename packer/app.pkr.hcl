packer {
  required_plugins {
    upcloud = {
      version = ">=1.0.0"
      source  = "github.com/UpCloudLtd/upcloud"
    }
  }
}

variable "username" {
  type    = string
  default = env("UPCLOUD_API_USER")
}

variable "password" {
  type    = string
  default = env("UPCLOUD_API_PASSWORD")
}

source "upcloud" "app" {
  username        = var.username
  password        = var.password
  zone            = "uk-lon1"
  storage_name    = "Ubuntu Server 20.04"
  template_prefix = "oc-uc-app"
}

build {
  sources = ["source.upcloud.app"]

  provisioner "file" {
    source = "../demoapp"
    destination = "/tmp/demoapp"
  }

  provisioner "shell" {
    inline = [
      "apt-get update",
      "apt-get upgrade -y",
      "useradd -m -U -s /bin/nologin demoapp",
      "mkdir -p /home/demoapp/bin",
      "mv /tmp/demoapp /home/demoapp/bin",
      "chown -R demoapp:demoapp /home/demoapp",
      "chmod u+x /home/demoapp/bin/demoapp"
    ]
  }
}

