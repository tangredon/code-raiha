terraform {
  backend "remote" {
    organization = "tangredon"

    workspaces {
      name = "raiha"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.70"
    }
  }
}

data "aws_api_gateway_rest_api" "api_raiha" {
  name = "raiha-stack"
}

variable "aws_access" {}

variable "aws_secret" {}

variable "aws_stage_name" {
  default = "Prod"
}

variable "aws_base_path" {
  default = "raiha"
}

provider "aws" {
  region     = "eu-central-1"
  access_key = var.aws_access
  secret_key = var.aws_secret
}

resource "aws_api_gateway_base_path_mapping" "gateway_mapping_raiha" {
  api_id      = "TBD"
  stage_name  = var.aws_stage_name
  domain_name = "serverless.tangredon.com"
  base_path   = var.aws_base_path
}

resource "aws_ecr_repository" "ecr_raiha" {
  name                 = "raiha"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

output "lb_address" { 
  value = data.aws_api_gateway_rest_api.api_raiha
}
