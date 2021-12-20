provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      owner              = "Luke McCleary"
      se-region          = "AMER-East E2"
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

data "tfe_workspace" "boundary_config" {
  name         = "fse-tf-atarc-boundary-config"
  organization = "PublicSector-ATARC"
}