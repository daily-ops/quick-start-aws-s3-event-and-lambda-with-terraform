
output "function_name" {
  description = "Name of the Lambda function."

  value = aws_lambda_function.handle_s3_notification.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function."

  value = aws_lambda_function.handle_s3_notification.arn
}