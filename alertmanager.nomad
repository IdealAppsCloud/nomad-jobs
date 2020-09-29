job "alertmanager" {
  datacenters = ["mgmt"]
  type = "service"

  group "alertmanager" {
    count = 1
    
    update {
      max_parallel     = 1
      canary           = 1
      auto_revert      = true
      auto_promote     = true
    }

    task "alertmanager" {
      driver = "docker"

      config {
        image = "prom/alertmanager:v0.21.0"
        port_map {
          alertmanager_ui= 9093
        }
        
        volumes = [
          "local/config/alertmanager.yml:/etc/alertmanager/config.yml",
        ]

        logging {
          type = "journald"
          config {
            tag = "ALERTMANAGER"
          }
        }
        
        port_map {
          http = 9093
        }
      }
      
      template {
        data = <<EOH
---
route:
 group_by: [cluster]
 # If an alert isn't caught by a route, send it slack.
 receiver: slack_general
 routes:
  # Send severity=slack alerts to slack.
  - match:
      severity: slack
    receiver: slack_general

receivers:
- name: slack_general
  slack_configs:
  - api_url: 'https://hooks.slack.com/services/token'
    channel: '#alerts'
EOH

        change_mode   = "signal"
        change_signal = "SIGHUP"
        destination   = "local/config/alertmanager.yml"
      }
      
      service {
        name = "alertmanager"
        tags = []
        port = "alertmanager_ui"
        check {
          type = "http"
          path = "/"
          interval = "10s"
          timeout = "2s"
        }
      }

      resources {
        cpu    = 100
        memory = 64
        network {
          mbits = 2
          port "alertmanager_ui" {}
        }
      }
    }
  }
}
