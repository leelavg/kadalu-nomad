# Network
network "cloud" {
  subnet = "10.5.0.0/16"
}

# Variables
variable "client_nodes" {
  default     = 0
  description = "Nomad agent will run in both client and server mode"
}

# All templates
template "consul_client_config" {
  source = <<-EOS
  datacenter = "dc1"
  retry_join = ["consul.container.shipyard.run"]
  EOS

  destination = "${data("consul-config")}/client.hcl"
}

template "consul_server_config" {
  source = <<-EOS
  data_dir = "/tmp/"
  log_level = "DEBUG"
  datacenter = "dc1"
  primary_datacenter = "dc1"
  server = true
  bootstrap_expect = 1
  ui = true
  bind_addr = "0.0.0.0"
  client_addr = "0.0.0.0"
  ports {
    grpc = 8502
  }
  connect {
    enabled = true
  }
  EOS

  destination = "${data("consul-config")}/server.hcl"
}

template "nomad_client_config" {
  source = <<-EOS
  plugin "docker" {
    config {
      allow_privileged = true
    }
  }
  EOS

  destination = "${data("nomad-config")}/client.hcl"
}

template "nomad_mount_shared" {
  # Hack till Shipyard supports supplying volume_options to Nomad Container
  source = <<-EOS
  #!/bin/bash

  CIDS=$(docker ps | grep nomad-cluster | awk '{print $1}')
  echo "Nomad container IDs: $CIDS"
  for cid in $CIDS
  do
    docker exec $cid sh -c 'mount --make-shared /etc/nomad.d/data'
  done
  echo "Made all data mounts in nomad containers as 'shared'"
  EOS

  destination = "${data("nomad-config")}/make-shared.sh"
}

container "consul" {
  image {
    name = "consul:1.10.1"
  }

  command = ["consul", "agent", "-config-file=/config/config.hcl"]

  volume {
    source      = "${data("consul-config")}/server.hcl"
    destination = "/config/config.hcl"
  }

  network {
    name = "network.cloud"
  }
}

# Consul ingress
container_ingress "consul-http" {
  target = "container.consul"

  port {
    local  = 8500
    remote = 8500
    host   = 18500
  }

  network {
    name = "network.cloud"
  }
}

# Nomad Cluster
nomad_cluster "dev" {
  client_nodes = "${var.client_nodes}"

  network {
    name = "network.cloud"
  }

  image {
    name = "consul:1.10.1"
  }

  client_config = "${data("nomad-config")}/client.hcl"
  consul_config = "${data("consul-config")}/client.hcl"

  # Default is 'bind' mount
  volume {
    source      = "${data("nomad-config")}/etc/nomad.d/data"
    destination = "/etc/nomad.d/data"
  }

  # Required for Kadalu CSI to use Gluster Native quota capabilities
  volume {
    source      = "/root/.ssh/id_rsa"
    destination = "/root/.ssh/id_rsa"
    read_only   = true
  }
}

# Make Nomad data mounts as shared
exec_local "mount_shared" {
  depends_on = ["nomad_cluster.dev"]
  cmd        = "bash"

  args = [
    "${data("nomad-config")}/make-shared.sh",
  ]
}

# Example nomad job to verify 'privileged' mode and 'consul' integration
nomad_job "example" {
  cluster    = "nomad_cluster.dev"
  depends_on = ["nomad_cluster.dev", "exec_local.mount_shared"]
  paths      = ["./example.nomad"]
}

output "NOMAD_ADDR" {
  value = "${cluster_api("nomad_cluster.dev")}"
}
