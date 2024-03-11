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

# module "prompt_management" {
#   source       = "github.com/FloRul/terraform-aws-esta-pms"
#   environment  = var.environment
#   project_name = var.project_name
#   aws_region   = var.aws_region
# }

module "esta_api" {
  source                 = "../../modules/api"
  project_name           = var.project_name
  environment            = var.environment
  aws_region             = var.aws_region
  cognito_user_pool_arns = [""]
  integrations           = []
}
