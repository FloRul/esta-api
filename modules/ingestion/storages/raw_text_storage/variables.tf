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

variable "queue_visibility_timeout_seconds" {
  description = "The visibility timeout for the SQS queue"
  type        = number
  nullable    = false
}
