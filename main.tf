terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
      ##### Adding parameters
    }
  }

  required_version = ">= 0.13"
}


provider "aws" {
  region              = "us-east-1"
  profile             = "abhipersonalaws"
  shared_config_files = ["/Users/abhibaj/.aws/config"]
}


####COMMENT: To see all the comments
####RESOURCELINKS: To see all the ResourceLinks
####EDIT: Edit it to make it more scalable


#### All Data go Here
data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}


##AWS RAM Resource Share for Subnet
resource "aws_ram_resource_share" "sharewithunifort" {
  name = "sharewithunifort"
  tags = {
    Owner = "AbhiBajaj"
  }
}

### AWS RAM Resource Share association
### For more
resource "aws_ram_resource_association" "resourceforsubnet" {
  resource_arn       = "arn:aws:ec2:us-east-1:XXXXXXX:subnet/subnet-0d4dde89b8b556ffc"   ###Need to create them via terraform
  resource_share_arn = aws_ram_resource_share.sharewithunifort.arn

}

####AWS S3 resource
resource "aws_s3_bucket" "s3terraformabhimanyu"{
 bucket = "s3terraformabhimanyu"   ###create a variable
 tags ={
  Owner = "AbhiBajaj"         ###Make these mandatory
 }
}

### Policy to allow AWS CloudTrail write trail in S3 bucket
## Ref https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy
resource "aws_s3_bucket_policy" "s3terraformabhimanyupolicy" {
  bucket = aws_s3_bucket.s3terraformabhimanyu.id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "${aws_s3_bucket.s3terraformabhimanyu.arn}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "${aws_s3_bucket.s3terraformabhimanyu.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY
}
####COMMENT: AWS CloudWatch
###RESOURCELINKS: For complete list  https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudtrail
resource "aws_cloudtrail" "cloudtrailabhi"{
 name = "cloudtrailabhi"
 s3_key_prefix = ""
 depends_on = ["aws_s3_bucket_policy.s3terraformabhimanyupolicy"]
 include_global_service_events = false
 s3_bucket_name = "s3terraformabhimanyu"
 tags = {
  Owner = "AbhiBajaj"
 }
}

#####COMMENT: AWS IAM ROLE FOR OKTA AUTHENTICATION
####RESOURCE LINKS: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
###EDIT: This can be edited and referrenced to output of aws_iam_saml_provider output in IdentityProvider directory

resource "aws_iam_role" "role_for_okta_access" {
  name               = "OktaAccessRole"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::XXXXXX:saml-provider/XXXXXXX"
      },
      "Action": "sts:AssumeRoleWithSAML",
      "Condition": {
        "StringEquals": {
          "SAML:aud": "https://signin.aws.amazon.com/saml"
        }
      }
    }
  ]
})
  tags = {
    Owner = "AbhiBajaj"
  }
}


#####COMMENT: AWS IAM ROLE POLICY FOR GIVING ADMIN ACCESS TO OKTA ROLE
####RESOURCE LINKS: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment
####EDIT

resource "aws_iam_policy" "policy_for_okta_access" {
  name        = "PolicyForOkta"
  description = "Policy for giving OKtaRole Admin Permission"
  tags = {
    Owner = "AbhiBajaj"
  }
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "*",
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "policy_attachment_for_okta" {
 role = aws_iam_role.role_for_okta_access.name
 policy_arn = aws_iam_policy.policy_for_okta_access.arn
}

#####COMMENT: AWS IAM USER FOR LETTING OKTA LIST ROLES
####RESOURCE LINKS: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user

resource "aws_iam_user" "user_for_okta_access" {
  name = "UserForOktaDefineRole"
  tags = {
    Owner = "AbhiBajaj"
  }
}


####COMMENT: AWS IAM POLICY FOR IAM USER
resource "aws_iam_user_policy" "polict_for_okta_user" {
  name = "PolicyForOktaUser"
  user = aws_iam_user.user_for_okta_access.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
            "iam:ListRoles",
            "iam:ListAccountAliases"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
