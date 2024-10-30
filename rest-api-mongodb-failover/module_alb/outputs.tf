output "alb_arn" {
  value = aws_alb.application_load_balancer.arn
}
output "alb_name" {
  value = aws_alb.application_load_balancer.name
}
output "alb_dns_name" {
  value = aws_alb.application_load_balancer.dns_name
}
output "zone_id" {
  value = aws_alb.application_load_balancer.zone_id
}
output "target_group_arn" {
  value = aws_alb_target_group.alb_fargate_tg.arn
}
output "target_group_name" {
  value = aws_alb_target_group.alb_fargate_tg.name
}
output "elb_http_listener_arn" {
  value = aws_alb_listener.application_listener.arn
}
