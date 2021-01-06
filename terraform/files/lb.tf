resource "yandex_lb_network_load_balancer" "app" {
  name = "lb-reddit-app"

  listener {
    name        = "http"
    port        = 80
    target_port = 9292
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.app_tg.id

    healthcheck {
      name = "http"
      http_options {
        port = 9292
        path = "/"
      }
    }
  }
}


resource "yandex_lb_target_group" "app_tg" {
  name = "lb-target-group-app"
  #   region_id = var.zone
  dynamic "target" {
    for_each = yandex_compute_instance.app.network_interface.0.ip_address
    content {
      # subnet_id = var.subnet_id
      subnet_id = yandex_vpc_subnet.app-subnet.id
      address   = target.value
    }
  }

}
