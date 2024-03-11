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
  region = "ca-central-1"
  default_tags {
    tags = {
      Environment = var.environment
      Terraform   = "true"
      Project     = var.project_name
    }
  }
}

module "prompt_management" {
  source       = "../../modules/template_management"
  environment  = var.environment
  project_name = var.project_name
  aws_region   = var.aws_region
}

module "esta_api" {
  depends_on             = [module.prompt_management]
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
          lambda_arn  = module.prompt_management.get_templates_lambda_arn
        },
        {
          http_method = "POST"
          lambda_arn  = module.prompt_management.post_template_lambda_arn
        },
        {
          http_method = "DELETE"
          lambda_arn  = module.prompt_management.delete_template_lambda_arn
        }
      ]
    },
  ]
}
