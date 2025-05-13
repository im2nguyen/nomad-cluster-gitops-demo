packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1.3.1"
    }
  }
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

variable "region" {
  type = string
}

variable "nomad_version" {
  type    = string
  default = "1.8.1"
}

variable "consul_version" {
  type    = string
  default = "1.18.2"
}

variable "consul_template_version" {
  type    = string
  default = "0.39.0"
}

variable "vault_version" {
  type    = string
  default = "1.17.0"
}

data "amazon-ami" "hashistack" {
  filters = {
    architecture                       = "x86_64"
    "block-device-mapping.volume-type" = "gp2"
    name                               = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
    root-device-type                   = "ebs"
    virtualization-type                = "hvm"
  }
  most_recent = true
  owners      = ["099720109477"]
  region      = var.region
}


source "amazon-ebs" "hashistack" {
  ami_name              = "hashistack-${local.timestamp}"
  instance_type         = "t2.medium"
  region                = var.region
  source_ami            = "${data.amazon-ami.hashistack.id}"
  ssh_username          = "ubuntu"
  force_deregister      = true
  force_delete_snapshot = true

  tags = {
    Name          = "nomad"
    source        = "hashicorp/learn"
    purpose       = "demo"
    OS_Version    = "Ubuntu"
    Release       = "Latest"
    Base_AMI_ID   = "{{ .SourceAMI }}"
    Base_AMI_Name = "{{ .SourceAMIName }}"
  }

  snapshot_tags = {
    Name    = "nomad"
    source  = "hashicorp/learn"
    purpose = "demo"
  }
}

build {
  hcp_packer_registry {
    bucket_name = "nomad-consul-vault"

    description = "AMI with Nomad, Consul and Vault"

    build_labels = {
      "nomad_version"           = var.nomad_version,
      "consul_version"          = var.consul_version,
      "consul_template_version" = var.consul_template_version,
      "vault_version"           = var.vault_version,
      "region"                  = var.region
    }
  }

  sources = ["source.amazon-ebs.hashistack"]

  provisioner "shell" {
    inline = ["sudo mkdir -p /ops/shared", "sudo chmod 777 -R /ops"]
  }

  provisioner "file" {
    destination = "/ops"
    source      = "shared"
  }

  provisioner "shell" {
    environment_vars = ["INSTALL_NVIDIA_DOCKER=false", "CLOUD_ENV=aws"]
    script           = "./shared/scripts/setup.sh"
    env = {
      "NOMADVERSION"          = var.nomad_version,
      "CONSULVERSION"         = var.consul_version,
      "CONSULTEMPLATEVERSION" = var.consul_template_version,
      "VAULTVERSION"          = var.vault_version
    }
  }
}
