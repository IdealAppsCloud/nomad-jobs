job "OpenFaas" {
  datacenters = ["mgmt"]
  type = "service"

  group "openfaas" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    task "faas" {
      driver = "docker"

      template {
        env = true
        destination   = "secrets/faas.env"

        data = <<EOH
{{ range service "statsd" }}
STATSD_ADDR="{{ .Address }}:{{ .Port }}"{{ end }}
EOH
      }

      config {
        image = "quay.io/nicholasjackson/faas-nomad:v0.4.3"

        args = [
          "-nomad_region", "${NOMAD_REGION}",
          "-nomad_addr", "${NOMAD_IP_http}:4646",
          "-consul_addr", "${NOMAD_IP_http}:8500",
          "-statsd_addr", "${STATSD_ADDR}",
          "-node_addr", "${NOMAD_IP_http}",
          "-basic_auth_secret_path", "/secrets",
          "-enable_basic_auth=false",
          "-enable_nomad_tls=false",
          "-nomad_tls_skip_verify",
          "-logger_level=DEBUG"
        ]

        port_map {
          http = 8080
        }
      }

      resources {
        cpu    = 500 # MHz
        memory = 128 # MB

        network {
          mbits = 10

          port "http" {}
        }
      }

      service {
        port = "http"
        name = "faasd-nomad"
        tags = ["faas"]
      }
    }

    task "gateway" {
      driver = "docker"
      template {
        env = true
        destination   = "secrets/gateway.env"

        data = <<EOH
functions_provider_url="http://{{ env "NOMAD_ADDR_faas_http" }}/"
{{ range service "prometheus" }}
faas_prometheus_host="{{ .Address }}"
faas_prometheus_port="{{ .Port }}"{{ end }}
{{ range service "nats" }}
faas_nats_address="{{ .Address }}"
faas_nats_port={{ .Port }}{{ end }}
scale_from_zero=true
EOH
      }

      config {
        image = "openfaas/gateway:0.18.11"

        port_map {
          http = 8080
          metrics = 8082
        }
      }

      resources {
        cpu    = 500 # MHz
        memory = 128 # MB

        network {
          mbits = 10

          port "http" {}
          port "metrics" {}
        }
      }

      service {
        port = "http"
        name = "gateway"
        tags = [
          "faas",
          "traefik.enable=true",
        ]
      }

      service {
        port = "metrics"
        name = "gateway-metrics"
        tags = [
          "faas",
          "metrics",
        ]
      }
    }
  }

  group "openfaas-idler" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    task "idler" {
      driver = "docker"

      template {
        env = true
        destination   = "secrets/idler.env"

        data = <<EOH
{{ range service "gateway" }}
gateway_url="http://{{ .Address }}:{{ .Port }}/"{{ end }}
{{ range service "prometheus" }}
prometheus_host="{{ .Address }}"
prometheus_port="{{ .Port }}"{{ end }}
inactivity_duration="2m"
reconcile_interval="1m"
write_debug=true
EOH
      }

      config {
        image = "openfaas/faas-idler:0.2.3"
      }

      resources {
        cpu    = 500 # MHz
        memory = 128 # MB

        network {
          mbits = 10
        }
      }

      service {
        name = "faasd-idler"
        tags = ["faas"]
      }
    }
  }

  group "openfaas-async" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    task "nats" {
      driver = "docker"

      config {
        image = "nats-streaming:0.11.2-linux"

        args = [
          "-store", "file", "-dir", "/tmp/nats",
          "-m", "8222",
          "-cid","faas-cluster",
        ]

        port_map {
          client = 4222,
          monitoring = 8222
          routing = 6222
        }
      }

      resources {
        cpu    = 500 # MHz
        memory = 128 # MB

        network {
          mbits = 1

          port "client" {
            static = 4222
          }

          port "monitoring" {
            static = 8222
          }

          port "routing" {
            static = 6222
          }
        }
      }

      service {
        port = "client"
        name = "nats"
        tags = ["faas"]

        check {
           type     = "http"
           port     = "monitoring"
           path     = "/connz"
           interval = "5s"
           timeout  = "2s"
        }
      }
    }
  }
}
