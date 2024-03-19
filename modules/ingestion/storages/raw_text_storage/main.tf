locals {
  queue_name  = "${var.project_name}-parsing-queue-${var.environment}"
  bucket_name = "${var.project_name}-raw-text-storage-${var.environment}"
}

module "raw_text_storage" {
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


resource "aws_sqs_queue" "parsing_queue" {
  name                       = local.queue_name
  visibility_timeout_seconds = var.queue_visibility_timeout_seconds
}

resource "aws_sqs_queue_policy" "sqs_policy" {
  queue_url = aws_sqs_queue.parsing_queue.url
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
    resources = [aws_sqs_queue.parsing_queue.arn]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [module.raw_text_storage.s3_bucket_arn]
    }
  }
}

resource "aws_s3_bucket_notification" "ingestion_notification" {
  bucket = module.raw_text_storage.s3_bucket_id

  queue {
    queue_arn     = aws_sqs_queue.parsing_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".txt"
  }
}
