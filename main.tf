provider "google" {
  version = "3.5.0"

  credentials = file(var.credentials_file)

  project = var.project
  region  = var.region
  zone    = var.zone
}
resource "google_compute_firewall" "vpc_network" {
  name    = "stack-server-firewall"
  network = google_compute_network.vpc_network.name


  allow {
    protocol = "tcp"
    ports    = ["22","4646","8500","8301","4647","8300","8200"]
  }

}

resource "google_compute_firewall" "cluster_network" {
  name = "cluster-setup"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  target_tags = ["stack-client"]
}

resource "google_compute_network" "vpc_network" {
  name = "stack-network"

}


resource "google_compute_instance" "stack_server" {
  name         = "stack-server"
  machine_type = "n1-standard-1"
  tags         = ["stack-server"]
  metadata = {
   startup-script = <<EOF
   sudo apt install -y jq
    IP=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
    sed -i -e 's/{REGION}/${var.region}/g' /etc/consul.d/server.json
    sed -i -e 's/{CLOUD}/gcp/g' /etc/consul.d/server.json
    sed -i -e "s/{PRIVATE-IPV4}/$${IP}/g" /etc/consul.d/server.json
    sed -i -e 's/{REGION}/${var.region}/g' /etc/nomad.d/server.hcl
    sed -i -e 's/{ZONE}/${var.region}/g' /etc/nomad.d/server.hcl
    sed -i -e 's/{CLOUD}/gcp/g' /etc/nomad.d/server.hcl
    sed -i -e "s/{PRIVATE-IPV4}/$${IP}/g" /etc/nomad.d/server.hcl
    systemctl enable consul-server
    systemctl start consul-server
    systemctl enable vault 
    systemctl start vault
    sleep 20
    curl \
    --request POST \
    --data '{"secret_shares": 1, "secret_threshold": 1}' \
    http://127.0.0.1:8200/v1/sys/init | jq . | cat | sudo tee /home/sachin/init.json

    export VAULT_TOKEN=$(cat /home/sachin/init.json | jq -r .root_token)
    sed -i -e "s/{VAULT_TOKEN}/$${VAULT_TOKEN}/g" /etc/nomad.d/server.hcl
    export VAULT_KEY=$(cat /home/sachin/init.json| jq -r .keys_base64 | jq '.[]')
    curl \
    --request POST \
    --data "{\"key\": $VAULT_KEY }" http://127.0.0.1:8200/v1/sys/unseal | jq . | cat | sudo tee /home/sachin/unseal.json

    curl \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{ "type":"nomad" }' \
    http://127.0.0.1:8200/v1/sys/mounts/nomad

    echo 'server=/consul/127.0.0.1#8600 
no-poll 
server=8.8.8.8 
local-service' | sudo tee /etc/dnsmasq.conf 

    
echo 'domain c.ngp-intern-platform.internal
search c.ngp-intern-platform.internal. google.internal.
nameserver 127.0.0.1
nameserver 169.254.169.254' | sudo tee /etc/resolv.conf

    sudo systemctl enable nomad-server
    sudo systemctl start nomad-server
    sudo systemctl restart dnsmasq
   EOF
   ssh-keys = "sachin:${file("~/.ssh/id_rsa.pub")}"
 }

  provisioner "local-exec" {
    command = "echo ${google_compute_instance.stack_server.name}:  ${google_compute_instance.stack_server.network_interface[0].access_config[0].nat_ip} >> ip_address.txt"
  }  

  boot_disk {
    initialize_params {
      image = "packer-1595780781"
    }
  }

  service_account {
    scopes = [
      "compute-ro",
      "storage-ro",
    ]
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }
}

resource "google_compute_instance" "stack_client" {
  depends_on   = [google_compute_instance.stack_server]
  name         = "stack-client"
  machine_type = "n1-standard-1"
  tags         = ["stack-client"]
  metadata = {
   startup-script = <<EOF
    IP=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
    sed -i -e 's/{REGION}/${var.region}/g' /etc/consul.d/client.json
    sed -i -e 's/{PROJECT}/${var.project}/g' /etc/consul.d/client.json
    sed -i -e 's/{CLOUD}/gcp/g' /etc/consul.d/client.json
    sed -i -e "s/{PRIVATE-IPV4}/$${IP}/g" /etc/consul.d/client.json
    sed -i -e 's/{REGION}/${var.region}/g' /etc/nomad.d/client.hcl
    sed -i -e 's/{ZONE}/${var.region}/g' /etc/nomad.d/client.hcl
    sed -i -e 's/{CLOUD}/gcp/g' /etc/nomad.d/client.hcl
    sed -i -e "s/{PRIVATE-IPV4}/$${IP}/g" /etc/nomad.d/client.hcl
    sed -i -e "s/{VAULT-IPV4}/${google_compute_instance.stack_server.network_interface[0].network_ip}/g" /etc/nomad.d/client.hcl
    echo 'server=/consul/127.0.0.1#8600 
no-poll 
server=8.8.8.8 
local-service' | sudo tee /etc/dnsmasq.conf 

    
echo 'domain c.ngp-intern-platform.internal
search c.ngp-intern-platform.internal. google.internal.
nameserver 127.0.0.1
nameserver 169.254.169.254' | sudo tee /etc/resolv.conf

    systemctl enable nomad-client
    systemctl enable consul-client
    systemctl start consul-client
    systemctl start nomad-client
    sudo systemctl restart dnsmasq
   EOF
   ssh-keys = "sachin:${file("~/.ssh/id_rsa.pub")}"
 }
  provisioner "local-exec" {
    command = "echo ${google_compute_instance.stack_client.name}:  ${google_compute_instance.stack_client.network_interface[0].access_config[0].nat_ip} >> ip_address.txt"
  }  

  boot_disk {
    initialize_params {
      image = "packer-1595598973"
    }
  }

  service_account {
    scopes = [
      "compute-ro",
      "storage-ro",
    ]
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }
}
