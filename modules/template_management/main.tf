
module "dynamo_index" {
  source      = "./dynamo"
  environment = var.environment
}

module "lambdas" {
  source                = "./lambdas"
  lambda_storage_bucket = var.lambda_storage_bucket
  template_dynamo_table = {
    name = module.dynamo_index.dynamo_table_name,
    arn  = module.dynamo_index.dynamo_table_arn,
  }
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
}
