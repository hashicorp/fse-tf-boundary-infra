terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
    backend "remote" {
      organization = "PublicSector-ATARC"
      workspaces {
        name = "fse-tf-atarc-boundary-infra"
      }
    }
  }