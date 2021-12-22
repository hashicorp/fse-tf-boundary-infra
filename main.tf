provider "aws" {
  region = "us-east-2"
  default_tags {
    tags = {
      owner              = "Luke McCleary"
      se-region          = "AMER-East Federal E2"
      purpose            = "boundry infra for zero trust demo"
      ttl                = "48"
      terraform          = "true"
      hc-internet-facing = "true"
    }
  }
}

provider "tfe" {
  token = var.tfc_token
}

data "tfe_outputs" "vpc" {
  workspace         = "fse-tf-atarc-aws-vpc"
  organization = "PublicSector-ATARC"
}

locals {
  vpc_id = data.tfe_outputs.vpc.values.vpc_id
  private_subs = data.tfe_outputs.vpc.values.public_subnet_ids
  public_subs = data.tfe_outputs.vpc.values.public_subnet_ids
}