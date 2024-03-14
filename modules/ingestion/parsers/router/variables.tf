variable "project_name" {
  nullable = false
  type     = string
}

variable "environment" {
  nullable = false
  type     = string
}

variable "ingestion_queue_arn" {
  nullable = false
  type     = string
}

variable "lambda_storage_bucket" {
  nullable = false
  type     = string
}

variable "aws_region" {
  nullable = false
  type     = string
}

variable "lambda_arns" {
  nullable = false
  type     = list(string)
}

variable "lambda_timeout" {
  nullable = false
  type     = number
}
