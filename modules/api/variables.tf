variable "api_name" {
  description = "The name of the API Gateway"
  type        = string
  nullable    = false
}

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

variable "api_log_retention_in_days" {
  description = "The number of days to retain the logs for the API Gateway"
  type        = number
  default     = 30
  validation {
    condition     = var.api_log_retention_in_days >= 0
    error_message = "The API log retention in days must be greater than or equal to 0"
  }
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

variable "integrations" {
  description = "The integrations for the API Gateway"
  type = list(object({
    path_part   = string
    http_method = string
    lambda_arn  = string
  }))

  nullable = true
}
