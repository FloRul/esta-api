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

  lambda_arns = [
    module.template_management.get_templates_lambda_arn,
    module.template_management.post_template_lambda_arn,
    module.template_management.delete_template_lambda_arn,
    module.inference_chat.lambda_arn,
  ]

  api_body = jsonencode({
    openapi = "3.0.1",
    info = {
      title   = "${var.project_name}-api-${var.environment}",
      version = "1.0.0"
    },
    paths = {
      "/templates" = {
        get = {
          "x-amazon-apigateway-integration" = {
            uri                 = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${module.template_management.get_templates_lambda_arn}/invocations"
            passthroughBehavior = "when_no_templates"
            httpMethod          = "POST"
            type                = "aws_proxy"
          }
        },
        options = {
          responses = {
            "200" = {
              description = "200 response"
              headers = {
                "Access-Control-Allow-Headers" = {
                  schema = {
                    type = "string"
                  }
                }
                "Access-Control-Allow-Methods" = {
                  schema = {
                    type = "string"
                  }
                }
                "Access-Control-Allow-Origin" = {
                  schema = {
                    type = "string"
                  }
                }
              }
            }
          },
          "x-amazon-apigateway-integration" = {
            type                = "mock"
            passthroughBehavior = "when_no_match"
            requestTemplates = {
              "application/json" = "{\"statusCode\": 200}"
            }
            responses = {
              default = {
                statusCode = 200
                responseParameters = {
                  "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
                  "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,GET,POST,DELETE'",
                  "method.response.header.Access-Control-Allow-Origin"  = "'*'"
                }
                responseTemplates = {
                  "application/json" = ""
                }
              }
            }
          }
        },
        method_responses = {
          "200" = {
            response_parameters = {
              "method.response.header.Access-Control-Allow-Headers" = true
              "method.response.header.Access-Control-Allow-Methods" = true
              "method.response.header.Access-Control-Allow-Origin"  = true
            }
            response_models = {
              "application/json" = "Empty"
            }
          }
        },
        post = {
          "x-amazon-apigateway-integration" = {
            uri                 = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${module.template_management.post_template_lambda_arn}/invocations"
            passthroughBehavior = "when_no_templates"
            httpMethod          = "POST"
            type                = "aws_proxy"
          }
        },
        delete = {
          "x-amazon-apigateway-integration" = {
            uri                 = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${module.template_management.delete_template_lambda_arn}/invocations"
            passthroughBehavior = "when_no_templates"
            httpMethod          = "POST"
            type                = "aws_proxy"
          }
        }
      },
      "/chat" = {
        post = {
          "x-amazon-apigateway-integration" = {
            uri                 = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${module.inference_chat.lambda_arn}/invocations"
            passthroughBehavior = "when_no_templates"
            httpMethod          = "POST"
            type                = "aws_proxy"
          }
        }
      }
    }
  })
}

# If you want to use Cognito User Pools for authorization, you can modify your Terraform code as follows:
# post = {
#   "x-amazon-apigateway-integration" = {
#     uri                 = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${module.template_management.post_templates_lambda_arn}/invocations"
#     passthroughBehavior = "when_no_templates"
#     httpMethod          = "POST"
#     type                = "aws_proxy"
#   },
#   security = [{
#     cognitoAuth = []
#   }]
# }

# And in the components section of your OpenAPI specification:

# components = {
#   securitySchemes = {
#     cognitoAuth = {
#       type = "apiKey",
#       name = "Authorization",
#       in = "header",
#       "x-amazon-apigateway-authorizer" = {
#         type = "cognito_user_pools",
#         providerARNs = var.cognito_user_pool_arns
#       }
#     }
#   }
# }
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

module "chat_history" {
  source       = "../../modules/chat_history"
  project_name = var.project_name
  environment  = var.environment
}

module "inference_chat" {
  depends_on             = [module.vectorstore, module.chat_history]
  source                 = "../../modules/inference/chat"
  lambda_repository_name = var.inference_chat_repository_name

  environment  = var.environment
  aws_region   = var.aws_region
  project_name = var.project_name

  lambda_sg_ids     = [module.vpc.vpc_sg_ids.lambda_sg]
  lambda_subnet_ids = module.vpc.public_subnets

  rds_instance_config = module.vectorstore.rds_instance_config

  dynamo_history_table_name  = module.chat_history.dynamo_table_name
  dynamo_template_table_name = module.template_management.template_dynamo_table_name
}

module "ingestion" {
  source                         = "../../modules/ingestion"
  project_name                   = var.project_name
  aws_region                     = var.aws_region
  environment                    = var.environment
  ingestion_supported_file_types = var.ingestion_supported_file_types
  lambda_storage_bucket          = module.lambda_storage.s3_bucket_id

  rds_instance_config = module.vectorstore.rds_instance_config
  lambda_sg_ids       = [module.vpc.vpc_sg_ids.lambda_sg]
  lambda_subnet_ids   = module.vpc.public_subnets

  recursive_indexer_repository_name = var.recursive_indexer_repository_name
}
