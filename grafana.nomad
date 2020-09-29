job "grafana" {
  datacenters = ["mgmt"]
  type = "service"

  group "grafana" {
    count = 1

    ephemeral_disk {
      migrate = true
    }
    
    task "grafana" {
      driver = "docker"

      config {
        image = "grafana/grafana:7.1.5"

        port_map {
          grafana_ui = 3000
        }

        volumes = [
          "local/datasources:/etc/grafana/provisioning/datasources",
        ]
      }

      env {
        GF_INSTALL_PLUGINS = "grafana-piechart-panel,natel-discrete-panel,jdbranham-diagram-panel,camptocamp-prometheus-alertmanager-datasource"
        GF_SECURITY_ADMIN_USER = "attachmentgenie"
        GF_SECURITY_ADMIN_PASSWORD = "$B03rt3un"
      }

      template {
        data = <<EOH
apiVersion: 1
datasources:
- name: Alertmanager
  type: camptocamp-prometheus-alertmanager-datasource
  access: proxy
  url: http://{{ range $i, $s := service "alertmanager" }}{{ if eq $i 0 }}{{.Address}}:{{.Port}}{{end}}{{end}}
  isDefault: false
  version: 1
  editable: false
EOH

        destination = "local/datasources/alertmanager.yaml"
      }

      template {
        data = <<EOH
apiVersion: 1
datasources:
- name: Loki
  type: loki
  access: proxy
  url: http://{{ range $i, $s := service "loki" }}{{ if eq $i 0 }}{{.Address}}:{{.Port}}{{end}}{{end}}
  isDefault: false
  version: 1
  editable: false
EOH

        destination = "local/datasources/loki.yaml"
      }

      resources {
        cpu    = 100
        memory = 64

        network {
          mbits = 10

          port "grafana_ui" {}
        }
      }
      
      template {
        data = <<EOH
apiVersion: 1
datasources:
- name: Prometheus
  type: prometheus
  access: proxy
  url: http://{{ range $i, $s := service "prometheus" }}{{ if eq $i 0 }}{{.Address}}:{{.Port}}{{end}}{{end}}
  isDefault: true
  version: 1
  editable: false
EOH

        destination = "local/datasources/prometheus.yaml"
      }
      
      service {
        name = "grafana"
        port = "grafana_ui"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.grafana.rule=Host(`grafana.bla-tech.com`)"
        ]
        check {
          type     = "http"
          path     = "/"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
