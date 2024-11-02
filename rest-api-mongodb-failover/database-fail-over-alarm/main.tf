provider "aws" {
  region = var.region
}

resource "aws_sns_topic" "sns_topic" {
  name = "sns-health"
}
resource "aws_cloudwatch_metric_alarm" "healthcheck_alarm" {
  alarm_name          = "route-53-health_check_alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60
  statistic           = "Minimum"
  threshold           = 0
  alarm_description   = "This metric monitors route-53-healthchecks"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.sns_topic.arn]
  treat_missing_data  = "breaching"

  dimensions = {
    HealthCheckId = var.health_check_id
  }
}
