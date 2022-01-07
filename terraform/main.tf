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

# data "aws_api_gateway_rest_api" "api_raiha" {
#   name = "raiha-stack"
# }

data "aws_caller_identity" "current" {}

locals {
    prefix              = "raiha"
    account_id          = data.aws_caller_identity.current.account_id
    ecr_repository_name = "raiha"
    ecr_image_tag       = "0.1.0-unstable.22"
}

variable "aws_access" {}
variable "aws_secret" {}

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

resource "aws_iam_role_policy" "api-invoker" {
    role     = aws_iam_role.lambda.id
    policy   = data.aws_iam_policy_document.execute-api.json
}

data "aws_iam_policy_document" "execute-api" {
    statement {
     sid = "all"
     actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
     ]
     resources = [
       "*"
     ]
   }
}

data "aws_ecr_repository" "repo" {
  name = "raiha"
}

data "aws_ecr_image" "lambda_image" {
    repository_name = local.ecr_repository_name
    image_tag       = local.ecr_image_tag
}

resource "aws_cloudwatch_log_group" "test-app-loggroup" {
  name              = "/aws/lambda/raiha-lambda"
  retention_in_days = 90
}

resource "aws_lambda_function" git {
    depends_on = [
        aws_cloudwatch_log_group.test-app-loggroup
    ]

    function_name = "${local.prefix}-lambda"
    role = aws_iam_role.lambda.arn
    // handler = "Raiha::Raiha.LambdaEntryPoint::FunctionHandlerAsync"
    timeout = 300
    image_uri = "${data.aws_ecr_repository.repo.repository_url}@${data.aws_ecr_image.lambda_image.id}"
    package_type = "Image"
}

resource "aws_api_gateway_rest_api" "example" {
  name        = "ServerlessExample"
  description = "Terraform Serverless Application Example"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.example.id}"
  parent_id   = "${aws_api_gateway_rest_api.example.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = "${aws_api_gateway_rest_api.example.id}"
  resource_id   = "${aws_api_gateway_resource.proxy.id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.example.id}"
  resource_id = "${aws_api_gateway_method.proxy.resource_id}"
  http_method = "${aws_api_gateway_method.proxy.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.git.invoke_arn}"
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = "${aws_api_gateway_rest_api.example.id}"
  resource_id   = "${aws_api_gateway_rest_api.example.root_resource_id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = "${aws_api_gateway_rest_api.example.id}"
  resource_id = "${aws_api_gateway_method.proxy_root.resource_id}"
  http_method = "${aws_api_gateway_method.proxy_root.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.git.invoke_arn}"
}

resource "aws_api_gateway_deployment" "example" {
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.lambda_root,
  ]

  rest_api_id = "${aws_api_gateway_rest_api.example.id}"
  stage_name  = "test"
}

resource "aws_lambda_permission" "apigw" {
    statement_id  = "AllowAPIGatewayInvoke"
    action        = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.git.arn}"
    principal     = "apigateway.amazonaws.com"

    # The /*/* portion grants access from any method on any resource
    # within the API Gateway "REST API".
    source_arn = "${replace(aws_api_gateway_deployment.example.execution_arn, "test", "")}*/*"
}

resource "aws_lambda_permission" "test-app-allow-cloudwatch" {
  statement_id  = "test-app-allow-cloudwatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.git.arn}"
  principal     = "logs.eu-central-1.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.test-app-loggroup.arn}:*"
}

# resource "aws_cloudwatch_log_subscription_filter" "test-app-cloudwatch-sumologic-lambda-subscription" {
#   depends_on      = [
#     aws_lambda_permission.test-app-allow-cloudwatch
#   ]
#   name            = "cloudwatch-sumologic-lambda-subscription"
#   log_group_name  = "${aws_cloudwatch_log_group.test-app-loggroup.name}"
#   filter_pattern  = ""
#   destination_arn = "${aws_lambda_function.git.arn}"
# }