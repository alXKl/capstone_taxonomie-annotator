output "dynamodb_name" {
  value       = aws_dynamodb_table.annotations_table.name
}

output "dynamodb_arn" {
  value       = aws_dynamodb_table.annotations_table.arn
}