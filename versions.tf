# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    tfe = {
      source = "hashicorp/tfe"
    }
  }
  backend "remote" {
    organization = "PublicSector-ATARC"
    workspaces {
      name = "fse-tf-atarc-boundary-infra"
    }
  }
}