provider "aws" {
  region = "ap-southeast-1"
  shared_credentials_file = "~/.aws/credentials"
  profile = "default"
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {}
provider "http" {}
