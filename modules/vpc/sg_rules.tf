resource "aws_security_group_rule" "bedrock_sg_ingress" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.lambda_sg.id
  security_group_id        = aws_security_group.bedrock_sg.id
}

resource "aws_security_group_rule" "database_sg_ingress_lambda" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lambda_sg.id
  security_group_id        = aws_security_group.database_sg.id
}

resource "aws_security_group_rule" "lambda_sg_egress_rds" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.database_sg.id
  security_group_id        = aws_security_group.lambda_sg.id
}

resource "aws_security_group_rule" "lambda_sg_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lambda_sg.id
}

resource "aws_security_group_rule" "lambda_sg_egress_sm" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.secret_manager_sg.id
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

# Allow traffic from the bastion security group to the RDS security group
resource "aws_security_group_rule" "allow_bastion_to_database" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.database_sg.id
  source_security_group_id = aws_security_group.bastion_sg.id
}

# Allow SSM traffic to the bastion security group
resource "aws_security_group_rule" "allow_ssm_to_bastion" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.bastion_sg.id
  source_security_group_id = aws_security_group.ssm_sg.id
}

# Allow egress traffic from the bastion security group to the SSM security group
resource "aws_security_group_rule" "allow_bastion_to_ssm" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.bastion_sg.id
  source_security_group_id = aws_security_group.ssm_sg.id
}

resource "aws_security_group_rule" "allow_ssm_inbound" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.ssm_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}
