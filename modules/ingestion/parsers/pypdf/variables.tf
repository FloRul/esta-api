variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
  nullable    = false
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  nullable    = false
}

variable "environment" {
  description = "The environment to deploy to"
  type        = string
  nullable    = false
}

variable "lambda_storage_bucket" {
  description = "The S3 bucket to store the lambda code"
  type        = string
  nullable    = false
}

variable "lambda_timeout" {
  description = "The timeout for the lambda functions"
  type        = number
}

variable "raw_text_storage_bucket" {
  description = "The S3 bucket to store the raw text"
  type        = string
  nullable    = false
}

variable "source_bucket_id" {
  description = "The ARN of the source bucket"
  type        = string
  nullable    = false
}
