job "dnsproblem" {
  datacenters = ["prod"]
  type = "service"

  group "hugo" {
    count = 2

    update {
      max_parallel     = 1
      canary           = 1
      auto_revert      = true
      auto_promote     = true
    }

    task "nginx" {
      driver = "docker"

      config {
        image = "623762986836.dkr.ecr.us-east-1.amazonaws.com/dnsproblem:1.0"
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
        name = "dnsproblem"
        tags = ["http","traefik.enable=true","traefik.frontend.rule=Host:dnsproblem.dev"]
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

