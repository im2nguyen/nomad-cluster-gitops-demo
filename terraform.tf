terraform {
  required_version = ">= 0.12"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.46.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 2"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.5"
    }
    consul = {
      source  = "hashicorp/consul"
      version = "2.21.0"
    }
    nomad = {
      source  = "hashicorp/nomad"
      version = "2.3.1"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "consul" {
  datacenter     = var.datacenter
  address        = "${data.hcp_vault_secrets_secret.nomad_ip.secret_value}:8443"
  token          = random_uuid.consul_mgmt_token.result
  ca_pem         = tls_self_signed_cert.datacenter_ca.cert_pem
  scheme         = "https"
  insecure_https = true
}

provider "nomad" {
  address     = "https://${data.hcp_vault_secrets_secret.nomad_ip.secret_value}:4646"
  region      = var.domain
  secret_id   = random_uuid.nomad_mgmt_token.result
  ca_pem      = tls_self_signed_cert.datacenter_ca.cert_pem
  skip_verify = true
  ignore_env_vars = {
    "NOMAD_ADDR" : true,
    "NOMAD_TOKEN" : true,
    "NOMAD_CACERT" : true,
    "NOMAD_TLS_SERVER_NAME" : true,
  }
}

# This is use to ensure that the provider is configured correctly on
# runs after the initial apply
data "hcp_vault_secrets_secret" "nomad_ip" {
  app_name    = hcp_vault_secrets_app.nomad.app_name
  secret_name = hcp_vault_secrets_secret.nomad_ip.secret_name
}