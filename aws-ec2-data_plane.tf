#-------------------------------------------------------------------------------
# Consul and Nomad Client(s)
#-------------------------------------------------------------------------------

resource "aws_instance" "public_client" {

  depends_on = [aws_instance.server]
  count      = var.public_client_count

  ami                         = data.hcp_packer_artifact.ami.external_identifier
  instance_type               = var.client_instance_type
  key_name                    = aws_key_pair.vm_ssh_key-pair.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [
    aws_security_group.ssh_ingress.id,
    aws_security_group.clients_ingress.id,
    aws_security_group.allow_all_internal.id
  ]

  # instance tags
  # ConsulAutoJoin is necessary for nodes to automatically join the cluster
  tags = {
    Name          = "${local.name}-ingress-client-${count.index}",
    ConsulJoinTag = "auto-join-${random_string.suffix.result}",
    NomadType     = "client"
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.root_block_device_size
    delete_on_termination = "true"
  }

  ebs_block_device {
    device_name           = "/dev/xvdd"
    volume_type           = "gp2"
    volume_size           = "50"
    delete_on_termination = "true"
  }

  user_data = templatefile("${path.module}/shared/data-scripts/user-data-client.sh", {
    domain                = var.domain,
    datacenter            = var.datacenter,
    consul_node_name      = "consul-public-client-${count.index}",
    cloud_env             = "aws",
    retry_join            = local.retry_join_consul,
    consul_encryption_key = random_id.consul_gossip_key.b64_std,
    consul_agent_token    = "${data.consul_acl_token_secret_id.consul-public-client-agent-token[count.index].secret_id}",
    consul_default_token  = "${data.consul_acl_token_secret_id.consul-public-client-default-token[count.index].secret_id}",
    nomad_node_name       = "nomad-public-client-${count.index}",
    nomad_agent_meta      = "isPublic = true, nodeRole = \"ingress\""
    nomad_agent_token     = "${data.consul_acl_token_secret_id.nomad-public-client-consul-token[count.index].secret_id}",
    ca_certificate        = base64gzip("${tls_self_signed_cert.datacenter_ca.cert_pem}"),
    agent_certificate     = base64gzip("${tls_locally_signed_cert.public_client_cert[count.index].cert_pem}"),
    agent_key             = base64gzip("${tls_private_key.public_client_key[count.index].private_key_pem}")
  })

  iam_instance_profile = aws_iam_instance_profile.instance_profile.name

  metadata_options {
    http_endpoint          = "enabled"
    instance_metadata_tags = "enabled"
  }
}

resource "aws_elb" "nomad_lb" {
  name = "${local.name}-lb"

  listener {
    instance_port     = 4444
    instance_protocol = "http"
    lb_port           = 8080
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 10
    target              = "TCP:4646"
    timeout             = 5
    interval            = 30
  }

  instances          = aws_instance.public_client[*].id
  availability_zones = data.aws_availability_zones.available.names
  security_groups = [
    aws_security_group.allow_all_internal.id,
    aws_security_group.lb_accept_app.id
  ]

  tags = {
    Name = "${local.name}-lb"
  }
}

resource "aws_security_group" "lb_accept_app" {
  name = "${local.name}-lb-app"

  # SSH
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
