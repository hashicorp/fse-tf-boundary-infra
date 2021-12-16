terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "0.27.0"
    }
  }
  backend "remote" {
    organization = "PublicSector-ATARC"
    workspaces {
      name = "fse-tf-atarc-boundary-infra"
    }
  }
}