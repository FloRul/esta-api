resource "aws_security_group_rule" "bedrock_sg_ingress" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.lambda_sg.id
  security_group_id        = aws_security_group.bedrock_sg.id
}

resource "aws_security_group_rule" "database_sg_ingress_bastion" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion_sg.id
  security_group_id        = aws_security_group.database_sg.id
}

resource "aws_security_group_rule" "database_sg_ingress_lambda" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lambda_sg.id
  security_group_id        = aws_security_group.database_sg.id
}

resource "aws_security_group_rule" "bastion_sg_ingress_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["75.152.59.245/32"]
  security_group_id = aws_security_group.bastion_sg.id
}

resource "aws_security_group_rule" "bastion_sg_ingress_ssm" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["75.152.59.245/32"]
  security_group_id = aws_security_group.bastion_sg.id
}

resource "aws_security_group_rule" "bastion_sg_egress_ssm" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.database_sg.id
  security_group_id        = aws_security_group.bastion_sg.id
}

resource "aws_security_group_rule" "lambda_sg_egress_rds" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.database_sg.id
  security_group_id        = aws_security_group.lambda_sg.id
}

resource "aws_security_group_rule" "lambda_sg_egress_sm" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.secret_manager_sg.id
  security_group_id        = aws_security_group.lambda_sg.id
}

resource "aws_security_group_rule" "lambda_sg_egress_s3" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "-1"
  source_security_group_id = aws_security_group.s3_sg.id
  security_group_id        = aws_security_group.lambda_sg.id
}

resource "aws_security_group_rule" "secret_manager_sg_ingress" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lambda_sg.id
  security_group_id        = aws_security_group.secret_manager_sg.id
}

resource "aws_security_group_rule" "dynamo_db_sg_ingress" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lambda_sg.id
  security_group_id        = aws_security_group.dynamo_db_sg.id
}

resource "aws_security_group_rule" "s3_sg_ingress" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lambda_sg.id
  security_group_id        = aws_security_group.s3_sg.id
}

resource "aws_security_group_rule" "s3_sg_egress" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lambda_sg.id
  security_group_id        = aws_security_group.s3_sg.id
}
