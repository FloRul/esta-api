output "bucket_id" {
  value = module.raw_text_storage.s3_bucket_id
}

output "bucket_arn" {
  value = module.raw_text_storage.s3_bucket_arn
}

output "parsing_queue_arn" {
  value = aws_sqs_queue.parsing_queue.arn
}
