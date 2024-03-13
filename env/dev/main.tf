terraform {
  backend "s3" {
    bucket = "esta-config-storage"
    key    = "env/dev/main.tfstate"
    region = "ca-central-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Environment = var.environment
      Terraform   = "true"
      Project     = var.project_name
    }
  }
}

module "lambda_storage" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "${var.project_name}-lambda-storage-${var.environment}"
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = {
    enabled = false
  }
  force_destroy = true
}

module "template_management" {
  source                = "../../modules/template_management"
  environment           = var.environment
  project_name          = var.project_name
  lambda_storage_bucket = module.lambda_storage.s3_bucket_id
  aws_region            = var.aws_region
}

module "esta_api" {
  depends_on             = [module.template_management]
  source                 = "../../modules/api"
  project_name           = var.project_name
  environment            = var.environment
  aws_region             = var.aws_region
  cognito_user_pool_arns = var.cognito_user_pool_arns
  integrations = [
    {
      path_part = "templates"
      details = [
        {
          http_method = "GET"
          lambda_arn  = module.template_management.get_templates_lambda_arn
        },
        {
          http_method = "POST"
          lambda_arn  = module.template_management.post_template_lambda_arn
        },
        {
          http_method = "DELETE"
          lambda_arn  = module.template_management.delete_template_lambda_arn
        }
      ]
    },
  ]
}

module "vpc" {
  source       = "../../modules/vpc"
  region       = var.aws_region
  environment  = var.environment
  project_name = var.project_name
}


module "vectorstore" {
  source       = "../../modules/vectorstore"
  project_name = var.project_name
  environment  = var.environment

  rds_sg_ids           = [module.vpc.vpc_sg_ids.database_sg]
  bastion_sg_ids       = [module.vpc.vpc_sg_ids.bastion_sg]
  db_subnet_group_name = module.vpc.db_subnet_group_name
  admin_subnet_id      = module.vpc.private_subnets[0]

  allocated_storage = var.vectorstore_storage
  bastion_state     = var.bastion_state
}

# module "inference_chat" {
#   source = "../../modules/inference/chat"

#   environment  = var.environment
#   aws_region   = var.aws_region
#   project_name = var.project_name

#   lambda_sg_ids     = [module.vpc.vpc_sg_ids.lambda_sg]
#   lambda_subnet_ids = module.vpc.public_subnets

#   rds_instance_config = module.vectorstore.rds_instance_config
# }
