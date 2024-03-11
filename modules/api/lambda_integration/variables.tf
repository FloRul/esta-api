variable "api_id" {
  type     = string
  nullable = false
}

variable "api_root_resource_id" {
  type     = string
  nullable = false
}

variable "api_path_part" {
  description = "The Api Gateway path"
  nullable    = false
  type        = string
}

variable "http_method" {
  description = "The Api Gateway http method"
  nullable    = false
  type        = string
}

variable "lambda_arn" {
  description = "The Lambda Function arn"
  nullable    = false
  type        = string
}

variable "lambda_name" {
  description = "The Lambda Function arn"
  nullable    = false
  type        = string
}

variable "aws_region" {
  type     = string
  nullable = false
  validation {
    condition     = can(regex("^(us|eu|ap|sa|ca)-(north|south|east|west)-[0-9]$", var.aws_region))
    error_message = "Invalid AWS region"
  }
}

variable "authorization_type" {
  description = "The Api Gateway method authorization type"
  nullable    = false
  type        = string
  default     = "NONE"
  validation {
    condition     = can(regex("^(NONE|AWS_IAM|CUSTOM|COGNITO_USER_POOLS)$", var.authorization_type))
    error_message = "Invalid authorization type"
  }
}

variable "authorizer_id" {
  description = "The Api Gateway method authorizer id"
  nullable    = true
  type        = string
  default     = null
}

variable "api_key_required" {
  description = "The Api Gateway method api key required"
  nullable    = false
  type        = bool
  default     = false

}
