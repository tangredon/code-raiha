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

provider "aws" {}

module "registry" {
  source = "../modules/registry"
  repository_name = "raiha"
}

module "gateway" {
  source = "../modules/gateway"

  service_name = "raiha"
  aws_region = var.aws_region
}