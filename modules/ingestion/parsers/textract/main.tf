locals {
  runtime              = "python3.11"
  powertools_layer_arn = "arn:aws:lambda:${var.aws_region}:017000801446:layer:AWSLambdaPowertoolsPythonV2:67"
  lambda_name          = "${var.project_name}-textract-parser-${var.environment}"
}

module "textract_parser" {
  source        = "terraform-aws-modules/lambda/aws"
  function_name = local.lambda_name
  handler       = "index.lambda_handler"
  runtime       = local.runtime
  publish       = true

  source_path = "${path.module}/src"

  store_on_s3 = true
  s3_bucket   = var.lambda_storage_bucket

  layers = [local.powertools_layer_arn]

  environment_variables = {
    DYNAMODB_TABLE = var.template_dynamo_table.name
  }
  attach_policy_statements = true
  policy_statements = {
    s3 = {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:PutObject",
      ]
      resources = [
        var.template_dynamo_table.arn,
      ]
    }

    log_group = {
      effect    = "Allow"
      actions   = ["logs:CreateLogGroup"]
      resources = ["arn:aws:logs:*:*:*"]
    }

    log_write = {
      effect = "Allow"
      resources = [
        "arn:aws:logs:*:*:log-group:/aws/${local.lambda_name}/*:*"
      ]
      actions = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
      ]
    }

    s3 = {
      effect    = "Allow"
      actions   = ["s3:*"]
      resources = ["*"]
    }

    textract = {
      effect    = "Allow"
      actions   = ["textract:*"]
      resources = ["*"]
    }
  }
}
