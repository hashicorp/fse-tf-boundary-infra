#output "boundary_lb" {
#  value = aws_lb.controller.dns_name
#}

#output "target_ips" {
#  value = aws_instance.target.*.private_ip
#}

output "keypair_pem" {
  value     = tls_private_key.boundary.private_key_pem
  sensitive = true
}

output "controller_public_ip" {
  value = aws_instance.controller[*].public_ip
}

output "controller_private_ip" {
  value = aws_instance.controller[*].private_ip
}

output "vault_public_ip" {
  value = aws_instance.vault.public_ip
}

output "vault_private_ip" {
  value = aws_instance.vault.private_ip
}

output "kms_recovery_key_id" {
  value = aws_kms_key.recovery.id
}

output "worker_public_ip" {
  value = aws_instance.worker[*].public_ip
}