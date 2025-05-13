output "consul_ui" {
  value = "https://${aws_instance.server[0].public_ip}:8443"
}

output "nomad_ui" {
  value = "https://${aws_instance.server[0].public_ip}:4646"
}

output "nomad_token" {
  value     = random_uuid.nomad_mgmt_token.result
  sensitive = true
}

output "consul_token" {
  value     = random_uuid.consul_mgmt_token.result
  sensitive = true
}

output "app_url" {
  value = "http://${aws_elb.nomad_lb.dns_name}:8080"
}
