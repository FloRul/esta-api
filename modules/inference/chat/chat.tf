locals {
  lambda_function_name = "${var.project_name}-inference-chat-${var.environment}"
  runtime              = "python3.11"
  timeout              = 60
  memory_size          = 256
  powertools_layer_arn = "arn:aws:lambda:${var.aws_region}:017000801446:layer:AWSLambdaPowertoolsPythonV2:67"
}


module "chat_inference_lambda" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = local.lambda_function_name

  create_package           = false
  image_uri                = data.aws_ecr_image.lambda_image.image_uri

  handler       = "index.lambda_handler"
  source_path   = "${path.module}/src"
  publish       = true
  timeout       = local.timeout
  memory_size   = local.memory_size
  runtime       = local.runtime

  vpc_security_group_ids = var.lambda_sg_ids
  vpc_subnet_ids         = var.lambda_subnet_ids
  layers                 = [local.powertools_layer_arn]

  environment_variables = {
    PGVECTOR_DRIVER   = "psycopg2"
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

    # dynamo_db = {
    #   effect = "Allow"

    #   resources = [
    #     "arn:aws:dynamodb:${var.aws_region}:446872271111:table/${var.dynamo_history_table_name}"
    #   ]

    #   actions = [
    #     "dynamodb:PutItem",
    #     "dynamodb:GetItem",
    #     "dynamodb:UpdateItem",
    #     "dynamodb:DeleteItem",
    #     "dynamodb:Scan",
    #     "dynamodb:Query",
    #     "dynamodb:BatchWriteItem",
    #     "dynamodb:BatchGetItem"
    #   ]
    # }
  }
}
