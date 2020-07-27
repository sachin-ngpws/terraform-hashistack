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
}

vault {
  enabled	= true
  address	= "http://{VAULT-IPV4}:8200"
}