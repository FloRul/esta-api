locals {
  lambda_function_name = "${var.project_name}-recursive-indexer-${var.environment}"
  runtime              = "python3.11"

  memory_size = 2048
}

data "aws_ecr_image" "lambda_image" {
  repository_name = var.lambda_repository_name
  most_recent     = true
}

module "recursive_indexer_lambda" {
  source = "terraform-aws-modules/lambda/aws"

  function_name  = local.lambda_function_name
  package_type   = "Image"
  create_package = false
  image_uri      = data.aws_ecr_image.lambda_image.image_uri

  handler     = "index.lambda_handler"
  timeout     = var.queue_visibility_timeout_seconds
  memory_size = local.memory_size
  runtime     = local.runtime

  vpc_security_group_ids = var.lambda_sg_ids
  vpc_subnet_ids         = var.lambda_subnet_ids

  environment_variables = {
    PGVECTOR_HOST     = var.rds_instance_config.db_host
    PGVECTOR_PORT     = var.rds_instance_config.db_port
    PGVECTOR_DATABASE = var.rds_instance_config.db_name
    PGVECTOR_PASS_ARN = var.rds_instance_config.db_pass_secret_arn
  }

  role_name                = "${local.lambda_function_name}-role"
  attach_policy_statements = true

  policy_statements = {
    log_group = {
      effect = "Allow"
      actions = [
        "logs:CreateLogGroup"
      ]
      resources = [
        "arn:aws:logs:*:*:*"
      ]
    }

    log_write = {
      effect = "Allow"

      resources = [
        "arn:aws:logs:*:*:log-group:/aws/${local.lambda_function_name}/*:*"
      ]

      actions = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
      ]
    }

    secret_manager = {
      effect = "Allow"

      resources = [
        var.rds_instance_config.db_pass_secret_arn
      ]

      actions = [
        "secretsmanager:GetSecretValue"
      ]
    }

    rds_connect_read = {
      effect = "Allow"

      resources = [
        "arn:aws:rds:${var.aws_region}:446872271111:db:${var.rds_instance_config.db_name}"
      ]

      actions = [
        "rds-db:connect",
        "rds-db:execute-statement",
        "rds-db:rollback-transaction",
        "rds-db:commit-transaction",
        "rds-db:beginTransaction"
      ]
    }
    access_network_interface = {
      effect = "Allow"

      resources = [
        "*"
      ]

      actions = [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface"
      ]
    }
  }
}

resource "aws_lambda_event_source_mapping" "parsing_queue_trigger" {
  event_source_arn = var.parsing_queue_arn
  enabled          = true
  function_name    = module.recursive_indexer_lambda.lambda_function_name
  batch_size       = 10
}
