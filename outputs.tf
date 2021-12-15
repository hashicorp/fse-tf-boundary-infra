#output "boundary_lb" {
#  value = aws_lb.controller.dns_name
#}

output "target_ips" {
  value = aws_instance.target.*.private_ip
}

output "keypair_pem" {
  value = tls_private_key.boundary.private_key_pem
  sensitive = true
}

output "controller_public_ip" {
  value = aws_instance.controller[*].public_ip
}

output "kms_recovery_key_id" {
  value = aws_kms_key.recovery.id
}