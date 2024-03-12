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

  database_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 4)]
  private_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 1)]

  create_database_subnet_route_table = true
  create_database_subnet_group       = true
  create_igw                         = true
}

resource "aws_vpc_endpoint" "bedrock_endpoint" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.bedrock-runtime"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.bedrock_sg.id]
  subnet_ids          = module.vpc.public_subnets
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssm_endpoint" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.bastion_sg.id]
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = true
}
resource "aws_vpc_endpoint" "ec2messages_endpoint" {
  vpc_id              = module.vpc.vpc_id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.ec2messages"
  security_group_ids  = [aws_security_group.bastion_sg.id]
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssmmessages_endpoint" {
  vpc_id              = module.vpc.vpc_id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.ssmmessages"
  security_group_ids  = [aws_security_group.bastion_sg.id]
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = true
}
