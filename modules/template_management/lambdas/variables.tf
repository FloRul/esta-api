variable "environment" {
  description = "The environment to deploy to"
  type        = string
  nullable    = false
}

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

variable "lambda_storage_bucket" {
  description = "The S3 bucket to store the lambda layer and packages in"
  type        = string
  nullable    = false
}

variable "template_dynamo_table" {
  description = "The name of the DynamoDB table to use"
  type = object({
    name = string
    arn  = string
  })
  nullable = false
}
