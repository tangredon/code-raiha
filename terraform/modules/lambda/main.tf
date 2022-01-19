data "aws_iam_role" "lambda" {
    name = "${var.service_name}-lambda-role"
}

data "aws_ecr_repository" "repo" {
  name = var.repo_name
}

data "aws_ecr_image" "image" {
  repository_name = var.repo_name
  image_tag       = var.image_tag
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.service_name}-lambda-${var.stage_name}"
  retention_in_days = 7
}

resource "aws_lambda_function" "main" {
  depends_on = [
      aws_cloudwatch_log_group.lambda_logs
  ]

  function_name = "${var.service_name}-lambda-${var.stage_name}"
  role = data.aws_iam_role.lambda.arn
  timeout = 5
  image_uri = "${data.aws_ecr_repository.repo.repository_url}@${data.aws_ecr_image.image.id}"
  package_type = "Image"

  publish = true

  tags = {
    environment = var.stage_name
    application = var.service_name
    rvi         = "${var.service_name}::${var.image_tag}"
    version     = var.image_tag
  }
}

resource "aws_lambda_alias" "lambda" {
  depends_on = [
    aws_lambda_function.main
  ]

  name             = "prod"
  description      = "a sample description"
  function_name    = aws_lambda_function.main.arn
  function_version = aws_lambda_function.main.version

  dynamic "routing_config" {
    for_each = []
    content {
      additional_version_weights = {
        aws_lambda_function.main.version = 0.0 
      }
    }
  }
}