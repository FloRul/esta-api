output "storage_bucket_id" {
  value = module.source_storage.s3_bucket_id
}

output "ingestion_queue_arn" {
  value = aws_sqs_queue.source_ingestion.arn
}
