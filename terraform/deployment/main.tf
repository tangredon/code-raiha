terraform {
  backend "remote" {
    organization = "tangredon"

    workspaces {
      prefix = "raiha-deployment-"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.70"
    }
  }
}

provider "aws" {}

module "lambda" {
  source = "../modules/lambda"

  repo_name = "raiha"
  service_name = "raiha"
  image_tag = var.image_tag
  stage_name = var.stage_name
}