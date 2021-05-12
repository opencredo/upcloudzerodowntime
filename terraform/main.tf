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
