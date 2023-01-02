terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.48.0"
    }
  }
}

provider "aws" {
 region              = "us-east-1"
 profile             = "abhipersonalaws"
 shared_config_files = ["/Users/abhibaj/.aws/config"]
}

resource "aws_iam_saml_provider" "default" {
  name                   = "OktaPersonal"
  saml_metadata_document = file("metadata.xml")
}
