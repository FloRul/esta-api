resource "aws_db_instance" "vectorstore" {
  ## Network settings
  vpc_security_group_ids = var.rds_sg_ids
  db_subnet_group_name   = var.db_subnet_group_name

  ## RDS instance settings
  allocated_storage   = var.allocated_storage
  storage_type        = var.storage_type
  deletion_protection = true

  # cannot be anything else than "postgres"
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  ## RDS instance configuration
  identifier          = "${var.project_name}-vectorstore-id-${var.environment}"
  username            = "${var.project_name}${var.environment}admin"
  publicly_accessible = false
  port                = var.db_port

  ## RDS instance options
  skip_final_snapshot          = true
  allow_major_version_upgrade  = false
  auto_minor_version_upgrade   = true
  performance_insights_enabled = true
  apply_immediately            = true
  parameter_group_name         = aws_db_parameter_group.default.name
  db_name                      = "${var.project_name}vectorstore${upper(var.environment)}"

  ## KMS settings
  manage_master_user_password   = true
  master_user_secret_kms_key_id = aws_kms_key.vectorstore_encryption_key.key_id

  kms_key_id        = aws_kms_key.vectorstore_encryption_key.arn
  storage_encrypted = true

  ## timeouts
  timeouts {
    create = "60m"
    delete = "60m"
    update = "60m"
  }
}

resource "aws_db_parameter_group" "default" {
  name   = "${var.project_name}-vectorstore-pg-${var.environment}"
  family = "postgres15"

  parameter {
    name  = "rds.force_ssl"
    value = 0
  }
}

resource "aws_kms_key" "vectorstore_encryption_key" {
  description             = "KMS key for encrypting the RDS instance"
  deletion_window_in_days = 7
  policy                  = data.aws_iam_policy_document.vectorstore_kms_key.json
}

data "aws_iam_policy_document" "vectorstore_kms_key" {
  statement {
    sid    = "Enable IAM user permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
}
