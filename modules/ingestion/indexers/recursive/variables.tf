variable "environment" {
  description = "The environment in which the resources are deployed"
  type        = string
  nullable    = false
}

variable "aws_region" {
  description = "The AWS region in which the resources are deployed"
  type        = string
  nullable    = false
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  nullable    = false
}

variable "lambda_sg_ids" {
  type     = list(string)
  nullable = false
}

variable "lambda_subnet_ids" {
  type     = list(string)
  nullable = false
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

variable "pg_vector_driver" {
  type     = string
  nullable = false
  default  = "psycopg2"
}

variable "lambda_repository_name" {
  type     = string
  nullable = false
}

variable "queue_visibility_timeout_seconds" {
  description = "The visibility timeout for the SQS queue"
  type        = number
  default     = 60
}

variable "parsing_queue_arn" {
  type     = string
  nullable = false
}
