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
