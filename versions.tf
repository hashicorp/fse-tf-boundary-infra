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