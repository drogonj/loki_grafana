storage "raft" {
  path = "/vault/data"
  node_id = "vault_2"
  retry_join {
    leader_api_addr = "https://vault_1:8200"
    leader_ca_cert_file = "/vault/ssl/ca.crt"
  }
  retry_join {
    leader_api_addr = "https://vault_3:8200"
    leader_ca_cert_file = "/vault/ssl/ca.crt"
  }
}

listener "tcp" {
  address = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  tls_cert_file   = "/vault/ssl/vault_2-combined.crt"
  tls_key_file    = "/vault/ssl/vault_2.key"
  tls_client_ca_file = "/vault/ssl/ca.crt"
  tls_disable_client_certs = false
  tls_min_version = "tls12"
  tls_disable = 0
}

ui = true
disable_mlock = true
cluster_addr = "https://vault_2:8201"
api_addr = "https://vault_2:8200"