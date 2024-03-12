resource "aws_security_group" "bedrock_sg" {
  name   = "bedrock-runtime-sg-${var.environment}"
  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group" "database_sg" {
  name   = "database-sg-${var.environment}"
  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group" "bastion_sg" {
  name   = "bastion-sg-${var.environment}"
  vpc_id = module.vpc.vpc_id
}
