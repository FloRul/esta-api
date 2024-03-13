
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "apigateway-${var.project_name}-${var.environment}"
  retention_in_days = var.api_log_retention_in_days
}

resource "aws_api_gateway_rest_api" "this" {
  name = "${var.project_name}-api-${var.environment}"
  body = var.api_body
}

data "aws_caller_identity" "current" {}

resource "aws_lambda_permission" "apigw" {
  for_each = {
    for arn in var.lambda_arns : arn => arn
  }

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "this" {
  depends_on = [aws_api_gateway_rest_api.this]
  lifecycle {
    create_before_destroy = true
  }
  triggers = {
    redeployment = timestamp()
  }
  rest_api_id = aws_api_gateway_rest_api.this.id
}

resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = var.environment
}

resource "aws_api_gateway_api_key" "this" {
  name = "${var.project_name}-key-${var.environment}"
}

## Auth and Authorizer
resource "aws_api_gateway_authorizer" "this" {
  name          = "${var.project_name}-authorizer-${var.environment}"
  rest_api_id   = aws_api_gateway_rest_api.this.id
  type          = "COGNITO_USER_POOLS"
  provider_arns = var.cognito_user_pool_arns
}


## Logging
resource "aws_api_gateway_account" "this" {
  cloudwatch_role_arn = aws_iam_role.this.arn
}

resource "aws_iam_role" "this" {
  name = "${var.project_name}-api-role-${var.environment}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "this" {
  name = "this"
  role = aws_iam_role.this.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:PutLogEvents",
        "logs:GetLogEvents",
        "logs:FilterLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}

