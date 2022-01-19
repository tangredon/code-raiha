terraform {
  backend "remote" {
    organization = "tangredon"

    workspaces {
      name = "raiha-deployment"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.70"
    }
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access
  secret_key = var.aws_secret
}

# module "lambda" {
#   source = "../modules/lambda"
# }