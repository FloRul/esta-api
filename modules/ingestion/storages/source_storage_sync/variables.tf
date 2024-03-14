variable "project_name" {
  description = "The name of the project"
  type        = string
  nullable    = false
}

variable "notification_filter_prefixes" {
  description = "The file extension to filter for notifications"
  type        = list(string)
  nullable    = false
}

variable "environment" {
  description = "The environment to deploy to"
  type        = string
  nullable    = false
}
