job "prometheus" {
  datacenters = ["mgmt"]
  type = "service"

  group "prometheus" {
    count = 1

    task "prometheus" {
      driver = "docker"

      config {
        image = "prom/prometheus:v2.20.1"

        args = [
          "--config.file=/etc/prometheus/config/prometheus.yml",
          "--storage.tsdb.path=/prometheus",
          "--web.console.libraries=/usr/share/prometheus/console_libraries",
          "--web.console.templates=/usr/share/prometheus/consoles",
        ]

        volumes = [
          "local/config:/etc/prometheus/config",
        ]

        port_map {
          prometheus_ui = 9090
        }
      }

      template {
        data = <<EOH
---
global:
  scrape_interval:     1s
  evaluation_interval: 1s

alerting:
 alertmanagers:
   - static_configs:
     - targets:
       - '{{ range $i, $s := service "alertmanager" }}{{ if eq $i 0 }}{{.Address}}:{{.Port}}{{end}}{{end}}'

scrape_configs:
  - job_name: alertmanager
    static_configs:
    - targets: ['{{ range $i, $s := service "alertmanager" }}{{ if eq $i 0 }}{{.Address}}:{{.Port}}{{end}}{{end}}']

  - job_name: autoscaler
    metrics_path: /v1/metrics
    params:
      format: ['prometheus']
    static_configs:
    - targets: ['{{ range $i, $s := service "autoscaler" }}{{ if eq $i 0 }}{{.Address}}:{{.Port}}{{end}}{{end}}']

  - job_name: consul
    metrics_path: /v1/agent/metrics
    params:
      format: ['prometheus']
    static_configs:
    - targets: ['{{ env "attr.unique.network.ip-address" }}:8500']

  - job_name: grafana
    static_configs:
    - targets: ['{{ range $i, $s := service "grafana" }}{{ if eq $i 0 }}{{.Address}}:{{.Port}}{{end}}{{end}}']

  - job_name: loki
    static_configs:
    - targets: ['{{ range $i, $s := service "loki" }}{{ if eq $i 0 }}{{.Address}}:{{.Port}}{{end}}{{end}}']

  - job_name: nomad
    metrics_path: /v1/metrics
    params:
      format: ['prometheus']
    static_configs:
    - targets: ['{{ env "attr.unique.network.ip-address" }}:4646']

  - job_name: node_exporter
    static_configs:
    - targets: ['{{ env "attr.unique.network.ip-address" }}:9100']

  - job_name: prometheus
    static_configs:
    - targets: ['{{ range $i, $s := service "prometheus" }}{{ if eq $i 0 }}{{.Address}}:{{.Port}}{{end}}{{end}}']

  - job_name: traefik
    static_configs:
    - targets: ['{{ env "attr.unique.network.ip-address" }}:8080']
EOH

        change_mode   = "signal"
        change_signal = "SIGHUP"
        destination   = "local/config/prometheus.yml"
      }

      resources {
        cpu    = 100
        memory = 256

        network {
          mbits = 10

          port "prometheus_ui" {}
        }
      }

      service {
        name = "prometheus"
        port = "prometheus_ui"

        check {
          type     = "http"
          path     = "/-/healthy"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}