variable "project_name" {
  description = "The name of the project"
  type        = string
  nullable    = false
}

variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
  nullable    = false
}

variable "environment" {
  description = "The environment to deploy to"
  type        = string
  nullable    = false
}

variable "lambda_storage_bucket" {
  description = "The name of the S3 bucket to store the lambda code"
  type        = string
  nullable    = false
}

variable "ingestion_supported_file_types" {
  description = "The file extension to filter for notifications"
  type        = list(string)
  nullable    = false
}

variable "rds_instance_config" {
  type = object({
    db_host            = string
    db_port            = number
    db_name            = string
    db_pass_secret_arn = string
  })
  nullable = false
}

variable "lambda_sg_ids" {
  type     = list(string)
  nullable = false
}

variable "lambda_subnet_ids" {
  type     = list(string)
  nullable = false
}

variable "recursive_indexer_repository_name" {
  description = "The name of the repository for the recursive indexer"
  type        = string
  nullable    = false
}
