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
    source = "demoapp"
    destination = "/tmp/demoapp"
  }

  provisioner "file" {
    source = "packer/artefact/demoapp.service"
    destination = "/tmp/demoapp.service"
  }

  provisioner "shell" {
    inline = [
      "apt-get update",
      "apt-get upgrade -y",
      "useradd -m -U -s /usr/sbin/nologin demoapp",
      "mkdir -p /home/demoapp/bin",
      "mv /tmp/demoapp /home/demoapp/bin",
      "chown -R demoapp:demoapp /home/demoapp",
      "chmod u+x /home/demoapp/bin/demoapp",
      "mv /tmp/demoapp.service /etc/systemd/system/demoapp.service",
      "systemctl enable demoapp.service --now"
    ]
  }
}

