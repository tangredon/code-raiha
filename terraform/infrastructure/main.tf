terraform {
  backend "remote" {
    organization = "tangredon"

    workspaces {
      name = "raiha-infrastructure"
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

module "registry" {
  source = "../modules/registry"
  repository_name = "raiha"
}

module "gateway" {
  source = "../modules/gateway"

  service_name = "raiha"
  aws_region = var.aws_region
}