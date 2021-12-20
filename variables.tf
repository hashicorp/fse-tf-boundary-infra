resource "random_pet" "test" {
  length = 1
}
locals {
  pub_cidrs  = "10.0.0.0/24"
  priv_cidrs = "10.0.100.0/24"
}

variable "psql_pw" {
  type        = string
  description = "password to the psql database"
}

variable "psql_user" {
  type        = string
  description = "psql database username"
}


variable "prefix" {
  default = "boundary-test"
}

variable "boundary_bin" {
  default = "~/projects/boundary/bin"
}

variable "num_workers" {
  default = 1
}

variable "num_controllers" {
  default = 1
}

variable "num_targets" {
  default = 1
}

variable "num_subnets_public" {
  default = 2
}

variable "num_subnets_private" {
  default = 1
}

variable "tls_cert_path" {
  default = "/etc/pki/tls/boundary/boundary.cert"
}

variable "tls_key_path" {
  default = "/etc/pki/tls/boundary/boundary.key"
}

variable "tls_disabled" {
  default = true
}

variable "kms_type" {
  default = "aws"
}

variable "tfc_token" {
}

variable "tfc_agent_token" {
description = "TFC agent token!!"
}