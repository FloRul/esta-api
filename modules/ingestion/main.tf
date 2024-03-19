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
    module.pypdf_parser.lambda_function_arn
  ]
  extension_lambda_mapping = jsonencode({
    ".pdf" = module.pypdf_parser.lambda_function_name
  })
}

module "raw_text_storage" {
  source                           = "./storages/raw_text_storage"
  project_name                     = var.project_name
  environment                      = var.environment
  queue_visibility_timeout_seconds = local.lambda_timeout
}

module "textract_parser" {
  source                  = "./parsers/textract"
  project_name            = var.project_name
  environment             = var.environment
  aws_region              = var.aws_region
  lambda_storage_bucket   = var.lambda_storage_bucket
  lambda_timeout          = local.lambda_timeout
  raw_text_storage_bucket = module.raw_text_storage.bucket_id
}

module "pypdf_parser" {
  source                  = "./parsers/pypdf"
  project_name            = var.project_name
  environment             = var.environment
  aws_region              = var.aws_region
  lambda_storage_bucket   = var.lambda_storage_bucket
  lambda_timeout          = local.lambda_timeout
  raw_text_storage_bucket = module.raw_text_storage.bucket_id
  source_bucket_id        = module.source_storage_sync.storage_bucket_id
}

module "recursive_indexer" {
  source                           = "./indexers/recursive"
  project_name                     = var.project_name
  environment                      = var.environment
  aws_region                       = var.aws_region
  rds_instance_config              = var.rds_instance_config
  lambda_sg_ids                    = var.lambda_sg_ids
  lambda_subnet_ids                = var.lambda_subnet_ids
  lambda_repository_name           = var.recursive_indexer_repository_name
  queue_visibility_timeout_seconds = local.lambda_timeout
  parsing_queue_arn                = module.raw_text_storage.parsing_queue_arn
}
