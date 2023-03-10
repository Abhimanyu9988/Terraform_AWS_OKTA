terraform {
  required_providers {
    okta = {
      source = "okta/okta"
      version = "3.39.0"
    }
  }
}

provider "okta" {
  api_token = "XXXXXXXXXXX""
  base_url = "okta.com"
  org_name = "trial-XXXXX"
}


####COMMENT: OKTA SAML APPLICATION FOR OKTA AWS CONFIGURATION
####RESOURCE: https://registry.terraform.io/providers/okta/okta/latest/docs/resources/app_saml
####EDIT: We have to make this scalable and useful when support for AWS FEDERATION is launched for app_saml
resource "okta_app_saml" "okta_aws_application" {
  label                    = "AWS Account Federation terraform"
  preconfigured_app = "amazon_aws"
  app_settings_json = <<EOT
{
  "appFilter":"okta",
  "awsEnvironmentType":"aws.amazon",
  "joinAllRoles": true,
  "loginURL": "https://console.aws.amazon.com/ec2/home",
  "roleValuePattern": "arn:aws:iam::XXXXXX:saml-provider/XXXX",
  "sessionDuration": 3600,
  "useGroupMapping": false
}
EOT
}
