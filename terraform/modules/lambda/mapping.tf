locals {
  target_domain = ( var.stage_name == "development" ? "alpha" :
                  ( var.stage_name == "staging"     ? "staging" : 
                  ( var.stage_name == "production"  ? "serverless" : 
                  "UNKNOWN"))) 
}

data "aws_api_gateway_rest_api" "lambda" {
  name = "${var.service_name}-api"
}

resource "aws_api_gateway_deployment" "lambda" {
  rest_api_id = data.aws_api_gateway_rest_api.lambda.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "lambda" {
  depends_on = [
    aws_api_gateway_deployment.lambda
  ]

  deployment_id = aws_api_gateway_deployment.lambda.id
  rest_api_id   = data.aws_api_gateway_rest_api.lambda.id
  stage_name    = var.stage_name

  variables = {
    stage_name = var.stage_name
  }
}

resource "aws_lambda_permission" "apigateway" {
  depends_on = [
    aws_api_gateway_stage.lambda
  ]

    statement_id  = "AllowAPIGatewayInvoke"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.main.arn
    qualifier     = aws_lambda_alias.lambda.name
    principal     = "apigateway.amazonaws.com"

    # The /*/*/* portion grants access to any stage/any method/any resource within the API Gateway "REST API".
    source_arn = "${data.aws_api_gateway_rest_api.lambda.execution_arn}/*/*/*"
}

resource "aws_lambda_permission" "cloudwatch" {
  statement_id  = "AllowCloudwatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.arn
  qualifier     = aws_lambda_alias.lambda.name
  principal     = "logs.eu-central-1.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.lambda_logs.arn}:*"
}

data "aws_api_gateway_domain_name" "serverless" {
  domain_name = "${local.target_domain}.tangredon.com"
}

resource "aws_api_gateway_base_path_mapping" "raiha" {
  depends_on = [
    aws_api_gateway_stage.lambda
  ]

  api_id      = data.aws_api_gateway_rest_api.lambda.id
  stage_name  = var.stage_name
  domain_name = data.aws_api_gateway_domain_name.serverless.domain_name
  base_path   = "${var.service_name}_"
}