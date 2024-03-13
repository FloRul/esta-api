variable "environment" {
  description = "The environment in which the RDS instance is being created"
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.environment))
    error_message = "The environment must be a lowercase string with no spaces"
  }
}

variable "project_name" {
  description = "The name of the project in which the RDS instance is being created"
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "The project name must be a lowercase string with no spaces"
  }
}

## Network settings

variable "db_subnet_group_name" {
  description = "The name of the DB subnet group to associate with the RDS instance"
  type        = string
}

variable "rds_sg_ids" {
  description = "The IDs of the security groups associated with the RDS instance"
  type        = set(string)
}

variable "admin_subnet_id" {
  description = "The ID of the subnet in which the bastion instance will be created"
  type        = string
}

variable "bastion_sg_ids" {
  description = "The IDs of the security groups associated with the bastion instance"
  type        = set(string)
}

variable "bastion_state" {
  description = "The desired state of the bastion instance"
  type        = string
  default     = "running"
  validation {
    condition     = var.bastion_state == "running" || var.bastion_state == "stopped"
    error_message = "The bastion state must be either 'running' or 'stopped'"
  }

}

## Storage settings
variable "allocated_storage" {
  description = "The amount of storage to allocate for the RDS instance"
  default     = 10
  type        = number
  validation {
    condition     = var.allocated_storage >= 10
    error_message = "The allocated storage must be at least 10 GB"
  }
}

variable "storage_type" {
  description = "The type of storage to use for the RDS instance"
  type        = string
  default     = "gp2"
  validation {
    condition     = var.storage_type == "gp2" || var.storage_type == "io1"
    error_message = "The storage type must be either 'gp2' or 'io1'"
  }
}

## RDS instance settings
variable "engine_version" {
  description = "The version of the database engine to use for the RDS instance"
  type        = string
  default     = "15.5"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.engine_version))
    error_message = "The engine version must be in the format 'X.Y'"
  }
  validation {
    condition     = tonumber(split(".", var.engine_version)[0]) >= 15
    error_message = "The major version must be greater than 15"
  }
}

variable "instance_class" {
  description = "The instance class to use for the RDS instance"
  type        = string
  default     = "db.t3.micro"
  validation {
    condition     = can(regex("^db\\.[a-z0-9]+\\.[a-z0-9]+$", var.instance_class))
    error_message = "The instance class must be in the format 'db.X.Y'"
  }
}

variable "db_port" {
  description = "The port on which the RDS instance will listen"
  type        = number
  default     = 5432
  validation {
    condition     = var.db_port >= 1024 && var.db_port <= 65535
    error_message = "The port must be a valid TCP port number"
  }
}

## KMS settings

