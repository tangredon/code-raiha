terraform {
  backend "remote" {
    organization = "tangredon"

    workspaces {
      name = "raiha-deploy"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.70"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  prefix              = "raiha"
  account_id          = data.aws_caller_identity.current.account_id
  ecr_repository_name = "raiha"
}

variable "aws_access" {}
variable "aws_secret" {}

variable "stage_name" {default = "test"}
variable "image_tag" {}

provider "aws" {
  region     = "eu-central-1"
  access_key = var.aws_access
  secret_key = var.aws_secret
}

resource "aws_iam_role" "lambda" {
  name = "${local.prefix}-lambda-role"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Effect": "Allow"
        }
    ]
}
  EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_ecr_repository" "repo" {
  name = local.ecr_repository_name
}

data "aws_ecr_image" "image" {
  repository_name = local.ecr_repository_name
  image_tag       = var.image_tag
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${local.prefix}-lambda-${var.stage_name}"
  retention_in_days = 7
}

resource "aws_lambda_function" "main" {
  depends_on = [
      aws_cloudwatch_log_group.lambda_logs
  ]

  function_name = "${local.prefix}-lambda-${var.stage_name}"
  role = aws_iam_role.lambda.arn
  timeout = 5
  image_uri = "${data.aws_ecr_repository.repo.repository_url}@${data.aws_ecr_image.image.id}"
  package_type = "Image"
}

resource "aws_api_gateway_rest_api" "lambda" {
  name        = "raiha-api"
  description = "Terraform Serverless Application Example"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.lambda.id
  parent_id   = aws_api_gateway_rest_api.lambda.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.lambda.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.lambda.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.main.invoke_arn
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.lambda.id
  resource_id   = aws_api_gateway_rest_api.lambda.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.lambda.id
  resource_id = aws_api_gateway_method.proxy_root.resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.main.invoke_arn
}

resource "aws_api_gateway_deployment" "lambda" {
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.lambda_root,
  ]

  rest_api_id = aws_api_gateway_rest_api.lambda.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "lambda" {
  depends_on = [
    aws_api_gateway_deployment.lambda
  ]

  deployment_id = aws_api_gateway_deployment.lambda.id
  rest_api_id   = aws_api_gateway_rest_api.lambda.id
  stage_name    = var.stage_name
}

resource "aws_lambda_permission" "apigateway" {
    statement_id  = "AllowAPIGatewayInvoke"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.main.arn
    principal     = "apigateway.amazonaws.com"

    # The /*/* portion grants access from any method on any resource within the API Gateway "REST API".
    source_arn = "${replace(aws_api_gateway_deployment.lambda.execution_arn, var.stage_name, "")}*/*"
}

resource "aws_lambda_permission" "cloudwatch" {
  statement_id  = "AllowCloudwatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.arn
  principal     = "logs.eu-central-1.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.lambda_logs.arn}:*"
}

data "aws_api_gateway_domain_name" "raiha" {
  domain_name = "serverless.tangredon.com"
}

resource "aws_api_gateway_base_path_mapping" "raiha" {
  depends_on = [
    aws_api_gateway_stage.lambda
  ]

  api_id      = aws_api_gateway_rest_api.lambda.id
  stage_name  = var.stage_name
  domain_name = data.aws_api_gateway_domain_name.raiha.domain_name
  base_path   = "${local.prefix}_"
}