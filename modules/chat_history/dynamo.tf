resource "aws_dynamodb_table" "chat_history" {
  name           = "${var.project_name}-chat-history-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "PK"
  range_key      = "SK"
  read_capacity  = 5
  write_capacity = 5

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }
}
