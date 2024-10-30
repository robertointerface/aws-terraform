/*
Classical Application Load balancer, since the Load balancer is internal we only need to have an HTTP listener (port 80)
*/
provider "aws" {
  region = var.region
}
data "aws_security_group" "lb_sg" {
  id = var.load_balancer_security_group_id
}
data "aws_subnet" "alb_subnet_1" {
  id = var.alb_subnet_id_first_option
}
data "aws_subnet" "alb_subnet_2" {
  id = var.alb_subnet_id_second_option
}
data "aws_vpc" "my_vpc" {
  id = var.vpc_id
}
resource "aws_alb" "application_load_balancer" {
  name               = "alb1"
  internal           = var.load_balancer_internal
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.lb_sg.id]
  subnets            = [data.aws_subnet.alb_subnet_1.id, data.aws_subnet.alb_subnet_2.id]
}
# create a target group for port 80 with target type "ip" for ECS service cluster
resource "aws_alb_target_group" "alb_fargate_tg" {
  name        = "rest-api-fargate-target"
  port        = 80
  target_type = "ip"
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.my_vpc.id
}
# attach the IP target group to load balancer
resource "aws_alb_listener" "application_listener" {
  load_balancer_arn = aws_alb.application_load_balancer.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_alb_target_group.alb_fargate_tg.arn
    type             = "forward"
  }
}

