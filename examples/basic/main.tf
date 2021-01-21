provider "aws" {
  region = "us-west-2"
}

module "vpc" {
  source      = "../../"
  environment = terraform.workspace
}
