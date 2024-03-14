locals {
  queue_name  = "${var.project_name}-ingestion-queue-${var.environment}"
  bucket_name = "${var.project_name}-ingestion-source-storage-${var.environment}"
}

module "source_storage" {
  source                   = "terraform-aws-modules/s3-bucket/aws"
  bucket                   = local.bucket_name
  acl                      = "private"
  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = {
    enabled = true
  }
  force_destroy = true
}

resource "aws_sqs_queue" "source_ingestion" {
  name = local.queue_name
}

resource "aws_sqs_queue_policy" "sqs_policy" {
  queue_url = aws_sqs_queue.source_ingestion.url
  policy    = data.aws_iam_policy_document.sqs_policy.json
}

data "aws_iam_policy_document" "sqs_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.source_ingestion.arn]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [module.source_storage.s3_bucket_arn]
    }
  }
}

resource "aws_s3_bucket_notification" "ingestion_notification" {
  bucket = module.source_storage.s3_bucket_id

  queue {
    queue_arn     = aws_sqs_queue.source_ingestion.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = join(",", var.notification_filter_prefixes)
  }
}
