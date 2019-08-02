job "monitoring" {
  datacenters = ["prod"]
  type = "service"

  group "metrics" {

    update {
      max_parallel     = 1
      canary           = 1
      auto_revert      = true
      auto_promote     = true
    }

    task "prometheus" {
      driver = "docker"

      config {
        image = "prom/prometheus:v2.8.1"
        port_map {
            http = 9090
        }
        logging {
          type = "journald"
          config {
            tag = "PROMETHEUS"
          }
        }
      }
      service {
        name = "prometheus"
        tags = [
          "metrics"
        ]
        port = "http"
        check {
          type = "http"
          path = "/targets"
          interval = "10s"
          timeout = "2s"
        }
      }

      resources {
        cpu    = 100
        memory = 128
        network {
          mbits = 10
          port "http" {}
        }
      }
    }

    task "grafana" {
      driver = "docker"

      config {
        image = "grafana/grafana"
        port_map {
            http = 3000
        }
        logging {
          type = "journald"
          config {
            tag = "GRAFANA"
          }
        }
      }
      
      service {
        name = "grafana"
        tags = [
          "metrics",
          "grafana",
          "http",
          "traefik.enable=true",
          "traefik.frontend.rule=Host:grafana.bla-tech.com"
        ]
        port = "http"
        check {
          type = "http"
          path = "/"
          interval = "10s"
          timeout = "2s"
        }
      }

      resources {
        cpu    = 100
        memory = 128
        network {
          mbits = 10
          port "http" {}
        }
      }
    }
  }
}

