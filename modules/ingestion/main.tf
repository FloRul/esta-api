locals {
  lambda_timeout = 900
}

module "source_storage_sync" {
  source                           = "./storages/source_storage_sync"
  project_name                     = var.project_name
  notification_filter_prefixes     = var.ingestion_supported_file_types
  environment                      = var.environment
  queue_visibility_timeout_seconds = local.lambda_timeout
}

module "parsing_router" {
  source                = "./parsers/router"
  project_name          = var.project_name
  environment           = var.environment
  aws_region            = var.aws_region
  lambda_storage_bucket = var.lambda_storage_bucket
  ingestion_queue_arn   = module.source_storage_sync.ingestion_queue_arn
  lambda_timeout        = local.lambda_timeout

  lambda_arns = [
    module.textract_parser.lambda_function_arn
  ]
  extension_lambda_mapping = jsonencode({
    ".pdf" = module.textract_parser.lambda_function_name
  })
}

module "raw_text_storage" {
  source       = "./storages/raw_text_storage"
  project_name = var.project_name
  environment  = var.environment
}

module "textract_parser" {
  source                = "./parsers/textract"
  project_name          = var.project_name
  environment           = var.environment
  aws_region            = var.aws_region
  lambda_storage_bucket = var.lambda_storage_bucket
  lambda_timeout        = local.lambda_timeout
}
