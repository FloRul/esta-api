locals {
  lambda_name = "${var.project_name}-parsing-router-${var.environment}"
  handler     = "index.lambda_handler"
  runtime     = "python3.11"
}

module "parsing_router_lambda" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = local.lambda_name
  handler       = local.handler
  runtime       = local.runtime
  publish       = true
  source_path   = "${path.module}/src"
  timeout       = var.lambda_timeout
  memory_size   = 2048
  store_on_s3   = true
  s3_bucket     = var.lambda_storage_bucket

  environment_variables = {
    LAMBDA_MAPPING = jsonencode({

    })
  }

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
    sqs = {
      effect = "Allow"
      resources = [
        var.ingestion_queue_arn
      ]
      actions = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:ChangeMessageVisibility"
      ]
    }

    # lambda_invoke = {
    #   effect    = "Allow"
    #   actions   = ["lambda:InvokeFunction"]
    #   resources = var.lambda_arns
    # }

    s3 = {
      effect = "Allow"
      actions = [
        "s3:*"
      ]
      resources = [
        "*"
        # "${module.raw_text_storage.s3_bucket_arn}/*",
        # module.raw_text_storage.s3_bucket_arn,
        # "arn:aws:s3:::${var.lambda_storage_bucket}/*",
        # "arn:aws:s3:::${var.lambda_storage_bucket}",
      ]
    }
    textract = {
      effect    = "Allow"
      actions   = ["textract:*"]
      resources = ["*"]
    }
  }
}

resource "aws_lambda_event_source_mapping" "ingestion_queue_trigger" {
  depends_on       = [module.parsing_router_lambda]
  event_source_arn = var.ingestion_queue_arn
  enabled          = true
  function_name    = module.parsing_router_lambda.lambda_function_name
  batch_size       = 10

}
