data "aws_availability_zones" "available" {}

locals {
  name     = "${var.project_name}-${var.environment}"
  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = local.name
  cidr   = local.vpc_cidr
  azs    = local.azs

  database_subnets                   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 4)]
  private_subnets                    = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 1)]
  public_subnets                     = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 8)]
  create_database_subnet_route_table = true
  create_database_subnet_group       = true
  create_igw                         = true
}
