locals {
  runtime              = "python3.11"
  powertools_layer_arn = "arn:aws:lambda:${var.aws_region}:017000801446:layer:AWSLambdaPowertoolsPythonV2:67"
  lambda_name          = "${var.project_name}-pypdf-parser-${var.environment}"
  output_bucket_arn    = "arn:aws:s3:::${var.raw_text_storage_bucket}"
  source_bucket_arn    = "arn:aws:s3:::${var.source_bucket_id}"
}

module "pypdf_parser" {
  source        = "terraform-aws-modules/lambda/aws"
  function_name = local.lambda_name
  handler       = "index.lambda_handler"
  runtime       = local.runtime
  publish       = true
  memory_size   = 2048
  timeout       = var.lambda_timeout
  source_path   = "${path.module}/src"

  store_on_s3 = true
  s3_bucket   = var.lambda_storage_bucket

  layers = [local.powertools_layer_arn]

  environment_variables = {
    RAW_TEXT_STORAGE = var.raw_text_storage_bucket
  }
  role_name                = "${local.lambda_name}-role"
  attach_policy_statements = true
  policy_statements = {

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
      effect = "Allow"
      actions = [
        "s3:PutObject",
        "s3:ListBucket",
        "s3:GetObject",
      ]
      resources = [
        local.output_bucket_arn,
        local.source_bucket_arn,
      ]
    }
  }
}
