resource "aws_s3_bucket" "lambda_storage" {
  bucket = "${var.project_name}-lambda-storage-${var.environment}"
}

module "dynamo_index" {
  source      = "./dynamo"
  environment = var.environment
}

module "lambdas" {
  source                = "./lambdas"
  lambda_storage_bucket = aws_s3_bucket.lambda_storage.bucket
  template_dynamo_table = {
    name = module.dynamo_index.table_name,
    arn  = module.dynamo_index.table_arn,
  }
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
}
