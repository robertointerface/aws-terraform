
data "aws_route53_zone" "hosted_zone" {
  name         = var.hosted_zone_name
  private_zone = false
}
resource "aws_acm_certificate" "roberto_practice_certificate" {
  domain_name       = var.domain_name
  validation_method = "DNS"
}

# set records to validate the above acm_certificate
resource "aws_route53_record" "alias_record" {
  for_each = {
    for dvo in aws_acm_certificate.roberto_practice_certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.hosted_zone.zone_id
}

# redirect traffic that comes from load balancer port 443 to fargate group, HTTPS needs a certificate
resource "aws_alb_listener" "application_listener_https" {
  load_balancer_arn = var.load_balancer_arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.roberto_practice_certificate.arn
  default_action {
    target_group_arn = var.target_group_arn
    type             = "forward"
  }
  depends_on = [aws_acm_certificate.roberto_practice_certificate]
}