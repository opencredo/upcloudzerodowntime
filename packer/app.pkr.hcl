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
    source      = "demoapp"
    destination = "/tmp/demoapp"
  }

  provisioner "file" {
    source      = "packer/artefact/demoapp.service"
    destination = "/tmp/demoapp.service"
  }

  provisioner "file" {
    source      = "packer/artefact/id_rsa_upcloud.pub"
    destination = "/tmp/id_rsa_upcloud.pub"
  }

  provisioner "file" {
    source      = "packer/artefact/opencredo"
    destination = "/tmp/opencredo"
  }

  provisioner "file" {
    source      = "packer/artefact/floating_ip.sh"
    destination = "/tmp/floating_ip.sh"
  }

  provisioner "file" {
    source      = "packer/artefact/floating_ip.service"
    destination = "/tmp/floating_ip.service"
  }

  provisioner "shell" {
    inline = [
      "set -x",
      "apt-get update",
      "apt-get upgrade -y",
      "grep -qxF 'source /etc/network/interfaces.d/*' /etc/network/interfaces || echo 'source /etc/network/interfaces.d/*' >> /etc/network/interfaces",
      "mv /tmp/floating_ip.sh /usr/local/bin/floating_ip.sh",
      "mv /tmp/floating_ip.service /etc/systemd/system/floating_ip.service",
      "systemctl enable floating_ip.service",
      "useradd -m -U -s /usr/sbin/nologin demoapp",
      "mkdir -p /home/demoapp/bin",
      "mv /tmp/demoapp /home/demoapp/bin",
      "chown -R demoapp:demoapp /home/demoapp",
      "chmod u+x /home/demoapp/bin/demoapp",
      "find /home/demoapp",
      "mv /tmp/demoapp.service /etc/systemd/system/demoapp.service",
      "systemctl enable demoapp.service --now",
      "useradd -m -U -s /bin/bash opencredo",
      "mkdir -p /home/opencredo/.ssh",
      "chmod 0700 /home/opencredo/.ssh",
      "mv /tmp/id_rsa_upcloud.pub /home/opencredo/.ssh/authorized_keys",
      "chown -R opencredo:opencredo /home/opencredo",
      "mv /tmp/opencredo /etc/sudoers.d/opencredo"
    ]
  }

  provisioner "goss" {
    pause_before = "30s"
    max_retries  = 5

    tests = ["packer/artefact/goss.yaml"]
  }
}

