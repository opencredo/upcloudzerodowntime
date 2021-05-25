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

  # Ensure the new server is responding before finishing deployment
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = <<-EOF
      fail_count=0

      while true; do
        response=$(curl --write-out %%{http_code} --silent --output /dev/null http://${self.network_interface[0].ip_address}:8080)
        echo "Response: $response"

        if [[ "$response" == "200" ]]; then
          echo "Application is available"
          exit 0
        fi

        fail_count=$((fail_count + 1))

        if (( fail_count > 30 )); then
          echo "Application is still unavailable"
          exit 2
        fi

        echo "Sleeping"
        sleep 10
      done
    EOF
  }
}

