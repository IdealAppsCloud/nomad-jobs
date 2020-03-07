job "cachet" {
  datacenters = ["mgmt"]
  type = "service"

  group "cachet" {
    count = 1

    task "postgres" {
      driver = "docker"

      config {
        image = "postgres:12.2"
        port_map {
          psql =5432
        }
      }

      env {
        POSTGRES_USER = "postgres"
        POSTGRES_PASSWORD = "postgres"
      }

      resources {
        cpu    = 100 # 100 MHz
        memory = 128 # 128 MB
        network {
          mbits = 10
          port  "psql"{}
        }
      }
    }

    task "cachet" {
      driver = "docker"

      config {
        image = "cachethq/docker:2.3.15"
        port_map {
          http = 8000
        }
      }

      env {
        DB_DRIVER = "pgsql"
        DB_HOST = "${NOMAD_IP_postgres_psql}"
        DB_PORT = "${NOMAD_PORT_postgres_psql}"
        DB_DATABASE = "postgres"
        DB_USERNAME = "postgres"
        DB_PASSWORD = "postgres"
        DB_PREFIX = "chq"
        APP_KEY = "base64:T48SNT9PDobnWoe9EDjoPoUl8US2mfhrJC/f9z+RGCE="
        APP_LOG = "errorlog"
        APP_ENV = "production"
        APP_DEBUG = false
        CACHE_DRIVER="apc"
        SESSION_DRIVER="apc"
        QUEUE_DRIVER="null"
        MAIL_DRIVER="log"
        DEBUG = false
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
        name = "cachet"
        tags = ["traefik.enable=true"]
        port = "http"
        check {
          type = "tcp"
          interval = "10s"
          timeout = "2s"
        }
      }
    }
  }
}
