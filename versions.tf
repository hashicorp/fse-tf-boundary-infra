terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
    backend "remote" {
    organization = "argocorp"
    workspaces {
      name = "boundary-demo-infra"
    }
  }
}