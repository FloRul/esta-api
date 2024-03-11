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
