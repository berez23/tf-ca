terraform {
  cloud {
    organization = "4securitas"
    workspaces {
      name = "CA-DnsShield"
    }
  }


  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  required_version = ">= 1.1.0"
}
