/*
Create all the EC2 template, Auto-Scaling group, Load balancer, listeners, route 53 alias to Load balancer and health
checks for the Load Balancer.
1 - EC2 Launch template for Amazon Linux that just prints the AWS region is located.
2 - Auto Scaling group that scales EC2 to a maximum of 3 in case of heavy traffic, Auto scaling group is located
at private subnets
3 - Application Load Balancer that directs traffic to the EC2 Auto Scaling group, ALB is located 2 public subnets.
4 - Route 53 alias that routes traffic from public hosted zone to ALB.
5 - Health check for ALB.
*/
provider "aws" {
  region = var.region
}
data "aws_security_group" "lb_sg" {
  id = var.load_balancer_security_group_id
}
data "aws_security_group" "ec2_sg" {
  id = var.asg_instance_security_group_id
}
data "aws_subnet" "public_1a" {
  id = var.subnet_public_1a_id
}
data "aws_subnet" "public_1b" {
  id = var.subnet_public_1b_id
}
data "aws_subnet" "private_1a" {
  id = var.subnet_private_1a_id
}
data "aws_subnet" "private_1b" {
  id = var.subnet_private_1b_id
}
data "aws_vpc" "my_vpc" {
  id = var.vpc_id
}
resource "aws_launch_template" "ec2_for_alb" {
  name                   = "LT1"
  vpc_security_group_ids = [data.aws_security_group.ec2_sg.id]
  instance_type          = "t2.micro"
  image_id               = var.instance_image_id
  user_data              = filebase64("./module_alb/zone_display.sh")
}
resource "aws_alb" "application_load_balancer" {
  name               = "alb1"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.lb_sg.id]
  subnets            = [data.aws_subnet.public_1a.id, data.aws_subnet.public_1b.id]
}
resource "aws_alb_target_group" "alb_tg" {
  name        = "TG1"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.my_vpc.id
}
resource "aws_alb_listener" "application_listener" {
  load_balancer_arn = aws_alb.application_load_balancer.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_alb_target_group.alb_tg.arn
    type             = "forward"
  }
}

resource "aws_autoscaling_group" "ALB_auto_scaling" {
  name                      = "alb_auto_scaling"
  max_size                  = 3
  min_size                  = 2
  desired_capacity          = 2
  health_check_grace_period = 50
  health_check_type         = "ELB"
  force_delete              = true
  launch_template {
    id      = aws_launch_template.ec2_for_alb.id
    version = "1"
  }
  vpc_zone_identifier = [data.aws_subnet.private_1a.id, data.aws_subnet.private_1b.id]
}
resource "aws_autoscaling_attachment" "ALB_attachment" {
  autoscaling_group_name = aws_autoscaling_group.ALB_auto_scaling.name
  lb_target_group_arn    = aws_alb_target_group.alb_tg.arn
}


data "aws_route53_zone" "hosted_zone" {
  name         = var.hosted_zone_name
  private_zone = false
}
resource "aws_acm_certificate" "roberto_practice_certificate" {
  domain_name       = var.domain_name
  validation_method = "DNS"
}
resource "aws_route53_record" "example" {
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
resource "aws_alb_listener" "application_listener_https" {
  load_balancer_arn = aws_alb.application_load_balancer.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.roberto_practice_certificate.arn
  default_action {
    target_group_arn = aws_alb_target_group.alb_tg.arn
    type             = "forward"
  }
  depends_on = [aws_acm_certificate.roberto_practice_certificate]
}
resource "aws_route53_health_check" "health_check_alb_port_443" {
  fqdn              = aws_alb.application_load_balancer.dns_name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/"
  failure_threshold = "2"
  request_interval  = "10"
  tags = {
    Name = "health-check-${var.region}-port443"
  }
}
