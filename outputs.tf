# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "keypair_pem" {
  value     = tls_private_key.boundary.private_key_pem
  sensitive = true
}

output "controller_public_ip" {
  value = aws_instance.controller.public_ip
}

output "controller_private_ip" {
  value = aws_instance.controller.private_ip
}

output "kms_recovery_key_id" {
  value = aws_kms_key.recovery.id
}

output "worker_public_ip" {
  value = aws_instance.worker.public_ip
}

output "worker_private_ip" {
  value = aws_instance.worker.private_ip
}

output "controller_sg_id" {
  value = aws_security_group.boundary.id
}
