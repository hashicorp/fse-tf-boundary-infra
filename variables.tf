# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "region" {
}

resource "random_pet" "test" {
  length = 1
}
locals {
  pub_cidrs  = cidrsubnets("10.0.0.0/24", 4, 4, 4, 4)
  priv_cidrs = cidrsubnets("10.0.100.0/24", 4, 4, 4, 4)
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