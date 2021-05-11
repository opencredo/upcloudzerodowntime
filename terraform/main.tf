resource "upcloud_server" "app" {
  hostname = "myapplication.com"
  zone     = "uk-lon1"
  plan     = "1xCPU-1GB"

  template {
    storage = var.template_id
    size    = 25
  }

  network_interface {
    type = "public"
  }
}
