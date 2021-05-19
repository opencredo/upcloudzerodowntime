resource "upcloud_server" "app" {
  hostname = "myapplication.com"
  zone     = "uk-lon1"
  plan     = "1xCPU-1GB"
  metadata = true

  template {
    storage = var.template_id
    size    = 25
  }

  network_interface {
    type = "public"
  }
}

resource "upcloud_floating_ip_address" "app_ip" {
  mac_address = upcloud_server.app.network_interface[0].mac_address
}

resource "null_resource" "metadata_update" {

  triggers = {
    mac_address = upcloud_floating_ip_address.app_ip.mac_address
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    //command     = <<-EOF
    //  curl -L -o upcloud_cli.tar.gz https://github.com/UpCloudLtd/upcloud-cli/releases/download/v1.0.0/upcloud-cli_1.0.0_linux_x86_64.tar.gz
    //  tar zxf upcloud_cli.tar.gz
    //  chmod +x upctl
    //  ./upctl server modify ${upcloud_server.app.id} --disable-metadata && ./upctl server modify ${upcloud_server.app.id} --enable-metadata
    //EOF
    command = <<-EOF
      auth=$(echo "$UPCLOUD_USERNAME:$UPCLOUD_PASSWORD" | base64)
      curl -H "Content-Type: application/json" -H"Authorization: Basic $auth" -XPUT https://api.upcloud.com/1.3/server/${upcloud_server.app.id} -d '{ "server": { "metadata": "no" } }'
      curl -H "Content-Type: application/json" -H"Authorization: Basic $auth" -XPUT https://api.upcloud.com/1.3/server/${upcloud_server.app.id} -d '{ "server": { "metadata": "yes" } }'
    EOF
  }
}
