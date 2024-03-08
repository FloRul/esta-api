terraform {
  backend "s3" {
    bucket = "esta-config-storage"
    key = "env/dev/main.tfstate"
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
      Project     = "levio-aws-demo-fev-dev"
    }
  }
}