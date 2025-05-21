output "lambda_function_name" {
  value = aws_lambda_function.rotate_key.function_name
}

output "sns_topic_arn" {
  value = aws_sns_topic.alert_topic.arn
}