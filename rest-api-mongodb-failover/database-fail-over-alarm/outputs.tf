output "cloudwatch_alarm_sns_arn" {
  value = aws_sns_topic.sns_topic.arn
}
output "sns_topic_name" {
  value = aws_sns_topic.sns_topic.name
}