data "hcp_packer_version" "ami" {
  bucket_name  = var.hcp_packer_bucket_name
  channel_name = "production"
}

data "hcp_packer_artifact" "ami" {
  bucket_name         = var.hcp_packer_bucket_name
  version_fingerprint = data.hcp_packer_version.ami.fingerprint
  platform            = "aws"
  region              = var.region
}


resource "hcp_vault_secrets_app" "nomad" {
  app_name = "nomad-stack"
}

resource "hcp_vault_secrets_secret" "nomad_ip" {
  app_name     = hcp_vault_secrets_app.nomad.app_name
  secret_name  = "nomad_ip"
  secret_value = aws_instance.server[0].public_ip
}

resource "hcp_vault_secrets_secret" "nomad_token" {
  app_name     = hcp_vault_secrets_app.nomad.app_name
  secret_name  = "nomad_token"
  secret_value = random_uuid.nomad_mgmt_token.result
}