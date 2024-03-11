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

variable "cognito_user_pool_arns" {
  description = "The ARNs of the Cognito User Pools"
  type        = list(string)
  nullable    = false
  validation {
    condition     = can(var.cognito_user_pool_arns)
    error_message = "The Cognito User Pool ARNs must be provided"
  }
}
