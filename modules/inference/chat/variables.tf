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
    db_host             = string
    db_port             = number
    db_name             = string
    db_user             = string
    db_pass_secret_name = string
  })
  nullable = false
}

variable "pg_vector_driver" {
  type     = string
  nullable = false
  default  = "psycopg2"
}

# variable "dynamo_history_table_name" {
#   type     = string
#   nullable = false
# }
