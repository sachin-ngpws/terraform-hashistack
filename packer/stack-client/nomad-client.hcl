advertise {
  http = "{PRIVATE-IPV4}"
  rpc  = "{PRIVATE-IPV4}"
  serf = "{PRIVATE-IPV4}"
}
data_dir = "/opt/nomad"

region = "{CLOUD}-{REGION}"

datacenter = "{CLOUD}-{ZONE}"

client {
  enabled      = true
  host_volume "run" {
     path = "/var/run"
  }

}

acl {
  enabled = true
}


vault {
  enabled	= true
  address	= "http://vault.service.consul:8200"
}