advertise {
  http = "{PRIVATE-IPV4}"
  rpc  = "{PRIVATE-IPV4}"
  serf = "{PRIVATE-IPV4}"
}

data_dir = "/opt/nomad"

region = "{CLOUD}-{REGION}"

datacenter = "{CLOUD}-{ZONE}"

server {
  enabled          = true
  bootstrap_expect = 1
}

vault {
  enabled	= true
  address	= "http://{PRIVATE-IPV4}:8200"
  token		= "{VAULT_TOKEN}"
}