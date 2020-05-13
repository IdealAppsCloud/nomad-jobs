job "aptly" {
  datacenters = ["mgmt"]
  type = "service"

  group "aptly" {
    count = 1

    task "aptly" {
      driver = "docker"

      config {
        image = "smirart/aptly:latest"
        port_map {
          http = 80
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
        name = "aptly"
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
