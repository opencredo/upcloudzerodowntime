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

  lifecycle {
    create_before_destroy = true
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = <<-EOF
      fail_count=0

      while true; do
        response=$(curl --write-out %%{http_code} --silent --output /dev/null ${self.network_interface[0].ip_address})

        if [[ "$response" == "200" ]]; then
          echo "Application is available"
          exit 0
        fi

        fail_count=$((fail_count + 1))

        if (( fail_count > 30 )); then
          echo "Application is still unavailable"
          exit 2
        fi

        sleep 10
      done
    EOF
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

    command = <<-EOF
      auth=$(echo "$UPCLOUD_USERNAME:$UPCLOUD_PASSWORD" | base64)
      curl -H "Content-Type: application/json" -H"Authorization: Basic $auth" -XPUT https://api.upcloud.com/1.3/server/${upcloud_server.app.id} -d '{ "server": { "metadata": "no" } }'
      curl -H "Content-Type: application/json" -H"Authorization: Basic $auth" -XPUT https://api.upcloud.com/1.3/server/${upcloud_server.app.id} -d '{ "server": { "metadata": "yes" } }'
    EOF
  }
}
