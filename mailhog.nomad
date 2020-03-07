job "mailhog" {
  datacenters = ["mgmt"]
  type = "service"

  group "mailhog" {
    count = 1

    task "mailhog" {
      driver = "docker"

      config {
        image = "mailhog/mailhog"
        port_map {
          http = 8025
          smtp = 1025
        }
      }

      resources {
        cpu    = 100 # 100 MHz
        memory = 128 # 128 MB
        network {
          mbits = 10
          port "http" {}
          port "smtp" {
	    static = "22525"
          }
        }
      }

      service {
        name = "mailhog"
        tags = ["traefik.enable=true"]
        port = "http"
        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }

      service {
        name = "smtp"
        port = "smtp"
        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
