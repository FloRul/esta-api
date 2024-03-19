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

resource "aws_security_group" "lambda_sg" {
  name   = "lambda-sg-${var.environment}"
  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group" "secret_manager_sg" {
  name   = "secret-manager-sg-${var.environment}"
  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group" "dynamo_db_sg" {
  name   = "dynamo-db-sg-${var.environment}"
  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group" "s3_sg" {
  name   = "s3-sg-${var.environment}"
  vpc_id = module.vpc.vpc_id

}
