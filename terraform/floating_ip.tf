resource "upcloud_floating_ip_address" "app_ip" {
  mac_address = upcloud_server.app.network_interface[0].mac_address
}

resource "null_resource" "metadata_update" {

  triggers = {
    mac_address = upcloud_floating_ip_address.app_ip.mac_address
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = <<-EOF
      auth=$(echo "$UPCLOUD_USERNAME:$UPCLOUD_PASSWORD" | base64)
      curl -H "Content-Type: application/json" -H"Authorization: Basic $auth" -XPUT https://api.upcloud.com/1.3/server/${upcloud_server.app.id} -d '{ "server": { "metadata": "no" } }'
      curl -H "Content-Type: application/json" -H"Authorization: Basic $auth" -XPUT https://api.upcloud.com/1.3/server/${upcloud_server.app.id} -d '{ "server": { "metadata": "yes" } }'
    EOF
  }
}

