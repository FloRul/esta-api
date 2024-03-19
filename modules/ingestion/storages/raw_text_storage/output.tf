output "bucket_id" {
  value = module.raw_text_storage.s3_bucket_id
}

output "parsing_queue_arn" {
  value = aws_sqs_queue.parsing_queue.arn
}
