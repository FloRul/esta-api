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
