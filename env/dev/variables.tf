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

## Api settings

variable "cognito_user_pool_arns" {
  description = "The ARNs of the Cognito User Pools"
  type        = list(string)
  nullable    = false
  validation {
    condition     = can(var.cognito_user_pool_arns)
    error_message = "The Cognito User Pool ARNs must be provided"
  }
}

## Vectorstore settings
variable "bastion_state" {
  description = "The desired state of the bastion instance"
  type        = string
  default     = "running"
  validation {
    condition     = var.bastion_state == "running" || var.bastion_state == "stopped"
    error_message = "The bastion state must be either 'running' or 'stopped'"
  }
}

variable "vectorstore_storage" {
  description = "The amount of storage to allocate for the RDS instance"
  type        = number
  nullable    = false
  validation {
    condition     = var.vectorstore_storage > 0
    error_message = "The storage must be greater than 0"
  }
}

## Inference settings
variable "inference_chat_repository_name" {
  type     = string
  nullable = false
  validation {
    condition     = can(var.inference_chat_repository_name)
    error_message = "The repository name must be provided"
  }
}

## Ingestion settings
variable "ingestion_supported_file_types" {
  description = "The file extension to filter for notifications ex: [\".pdf\", \".docx\"]"
  type        = list(string)
  nullable    = false
}
