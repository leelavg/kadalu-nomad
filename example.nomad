# Sample job to verify 'privileged' containers and consul integration
job "http-echo-dynamic-service" {
  datacenters = ["dc1"]

  group "echo" {
    count = 1

    task "server" {
      driver = "docker"

      config {
        image      = "hashicorp/http-echo:latest"
        privileged = true

        args = [
          "-listen",
          ":${NOMAD_PORT_http}",
          "-text",
          "Hello and welcome to ${NOMAD_IP_http} running on port ${NOMAD_PORT_http}",
        ]
      }

      resources {
        network {
          mbits = 10
          port  "http"{}
        }
      }

      service {
        name = "http-echo"
        port = "http"

        tags = [
          "example",
          "urlprefix-/http-echo",
        ]

        check {
          type     = "http"
          path     = "/health"
          interval = "2s"
          timeout  = "2s"
        }
      }
    }
  }
}
