module "raw_text_storage" {
  source                   = "terraform-aws-modules/s3-bucket/aws"
  bucket                   = "${var.project_name}-raw-text-storage-${var.environment}"
  acl                      = "private"
  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = {
    enabled = true
  }
  force_destroy = true
}
