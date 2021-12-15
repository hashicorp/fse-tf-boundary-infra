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