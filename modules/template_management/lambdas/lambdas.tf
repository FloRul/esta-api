locals {
  runtime                              = "python3.11"
  powertools_layer_arn                 = "arn:aws:lambda:${var.aws_region}:017000801446:layer:AWSLambdaPowertoolsPythonV2:67"
  get_templates_lambda_function_name   = "${var.project_name}-get-templates-${var.environment}"
  post_template_lambda_function_name   = "${var.project_name}-post-template-${var.environment}"
  delete_template_lambda_function_name = "${var.project_name}-delete-template-${var.environment}"
}

module "get_templates" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = local.get_templates_lambda_function_name
  handler       = "index.lambda_handler"
  runtime       = local.runtime
  publish       = true

  source_path = "${path.module}/get_templates/src"

  store_on_s3 = true
  s3_bucket   = var.lambda_storage_bucket

  layers = [local.powertools_layer_arn]

  environment_variables = {
    DYNAMODB_TABLE = var.template_dynamo_table.name
  }
  attach_policy_statements = true
  policy_statements = {
    dynamodb = {
      effect = "Allow"
      actions = [
        "dynamodb:Scan",
        "dynamodb:GetItem",
        "dynamodb:Query",
        "dynamodb:BatchGetItem",
      ]
      resources = [
        var.template_dynamo_table.arn,
      ]
    }

    log_write = {
      effect = "Allow"

      resources = [
        "arn:aws:logs:*:*:log-group:/aws/${local.get_templates_lambda_function_name}/*:*"
      ]

      actions = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
      ]
    }
  }
}

module "delete_template" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = delete_template_lambda_function_name
  handler       = "index.lambda_handler"
  runtime       = local.runtime
  publish       = true

  source_path = "${path.module}/delete_template/src"

  store_on_s3 = true
  s3_bucket   = var.lambda_storage_bucket

  layers = [local.powertools_layer_arn]

  environment_variables = {
    DYNAMODB_TABLE = var.template_dynamo_table.name
  }

  attach_policy_statements = true
  policy_statements = {
    dynamodb = {
      effect = "Allow"
      actions = [
        "dynamodb:DeleteItem",
      ]
      resources = [
        var.template_dynamo_table.arn,
      ]
    }
    log_write = {
      effect = "Allow"

      resources = [
        "arn:aws:logs:*:*:log-group:/aws/${local.delete_template_lambda_function_name}/*:*"
      ]

      actions = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
      ]
    }
  }
}

module "post_template" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = local.post_template_lambda_function_name
  handler       = "index.lambda_handler"
  runtime       = local.runtime
  publish       = true

  source_path = "${path.module}/post_template/src"

  store_on_s3 = true
  s3_bucket   = var.lambda_storage_bucket

  layers = [local.powertools_layer_arn]

  environment_variables = {
    DYNAMODB_TABLE = var.template_dynamo_table.name
  }

  attach_policy_statements = true
  policy_statements = {
    dynamodb = {
      effect = "Allow"
      actions = [
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:GetItem",
      ]
      resources = [
        var.template_dynamo_table.arn,
      ]
    }
    log_write = {
      effect = "Allow"

      resources = [
        "arn:aws:logs:*:*:log-group:/aws/${local.post_template_lambda_function_name}/*:*"
      ]

      actions = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
      ]
    }
  }
}
