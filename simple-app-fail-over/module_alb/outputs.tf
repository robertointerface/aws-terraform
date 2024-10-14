output "alb_id" {
  value = aws_alb.application_load_balancer.id
}
output "zone_id" {
  value = aws_alb.application_load_balancer.zone_id
}
output "alb_dns_name" {
  value = aws_alb.application_load_balancer.dns_name
}
# output "health_check_id_port_80" {
#   value = aws_route53_health_check.health_check_alb_port_80.id
# }
output "health_check_id_port_443" {
  value = aws_route53_health_check.health_check_alb_port_443.id
}