job "toxiproxy" {
  datacenters = ["mgmt"]
  type = "service"

  group "toxiproxy" {
    count = 1

    task "toxiproxy" {
      driver = "docker"

      config {
        image = "shopify/toxiproxy:2.1.4"
        port_map {
          http = 8474
        }
      }

      resources {
        cpu    = 100 # 100 MHz
        memory = 128 # 128 MB
        network {
          mbits = 10
          port "http" {}
        }
      }

      service {
        name = "toxiproxy"
        tags = ["traefik.enable=true"]
        port = "http"
        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
