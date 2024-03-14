module "template_index_table" {
  source = "terraform-aws-modules/dynamodb-table/aws"

  name         = "${var.project_name}-templates-${var.environment}"
  hash_key     = "PK"
  billing_mode = "PAY_PER_REQUEST"

  attributes = [
    {
      name = "PK"
      type = "S"
    },
  ]
}
