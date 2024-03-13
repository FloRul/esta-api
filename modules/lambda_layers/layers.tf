module "llamaindex_layer" {
  source = "terraform-aws-modules/lambda/aws"

  create_layer = true

  layer_name          = "llamaindex-layer"
  description         = "My amazing lambda layer (deployed from S3)"
  compatible_runtimes = ["python3.11"]

  source_path = "${path.module}/llama-index"

  store_on_s3 = true
  s3_bucket   = var.layers_storage
}
