provider "aws" {
  region = var.region
}
data "aws_route53_zone" "roberto_practice_zone" {
  name         = var.domain_name
  private_zone = false
}
data "aws_vpc" "rest_api_vpc" {
  id = var.vpc_id
}
# Security group for the Load Balancer, allow to take anything from inside the VPC
resource "aws_security_group" "all_all_in_from_inside_vpc" {
  name        = "load_balancer_sg"
  description = "allow ssh, http and https for load balancer in, allow all out"
  vpc_id      = var.vpc_id
}
resource "aws_vpc_security_group_ingress_rule" "inbound_allow_all_alb" {
  security_group_id = aws_security_group.all_all_in_from_inside_vpc.id
  from_port         = -1
  to_port           = -1
  ip_protocol       = -1
  cidr_ipv4         = data.aws_vpc.rest_api_vpc.cidr_block
}
resource "aws_vpc_security_group_egress_rule" "outbound_allow_all_alb" {
  security_group_id = aws_security_group.all_all_in_from_inside_vpc.id
  from_port         = -1
  to_port           = -1
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
}
# Rest-api Load balancer
module "rest_api_alb_london" {
  source                          = "../module_alb"
  region                          = var.region
  load_balancer_internal          = var.rest_api_internal_load_balancer
  vpc_id                          = var.vpc_id
  alb_subnet_id_first_option      = var.alb_subnet_id_first_option
  alb_subnet_id_second_option     = var.alb_subnet_id_second_option
  load_balancer_security_group_id = aws_security_group.all_all_in_from_inside_vpc.id
}
module "alb_https_listener" {
  count             = var.rest_api_internal_load_balancer ? 0 : 1
  source            = "../module_alb_https_listener"
  load_balancer_arn = module.rest_api_alb_london.alb_arn
  target_group_arn  = module.rest_api_alb_london.target_group_arn
  domain_name       = var.domain_name
  hosted_zone_name  = var.hosted_zone_name
}
# ECS service
module "ECS_service" {
  source                             = "../module_ecs"
  region                             = var.region
  vpc_id                             = var.vpc_id
  ecs_service_subnet_first_option    = var.ecs_service_subnet_id_first_option
  ecs_service_subnet_second_option   = var.ecs_service_subnet_id_second_option
  load_balancer_security_group_id    = aws_security_group.all_all_in_from_inside_vpc.id
  mongo_db_security_group_id         = var.mongo_db_security_group_id
  ecr_repository_ecommerce_rest_api  = "rest-api"
  ecr_tag_ecommerce_rest_api         = "latest"
  mongo_cluster_password_secret_name = "document_db_e_commerce_regual_user_credentials"
  fargate_target_group_name          = module.rest_api_alb_london.target_group_name
  fargate_target_group_arn           = module.rest_api_alb_london.target_group_arn
  task_IAM_role_name                 = "e-commerce-api-role"
  load_balancer_name                 = module.rest_api_alb_london.alb_name
  load_balancer_arn                  = module.rest_api_alb_london.alb_arn
  db_host                            = var.document_db_host
}
# The entry point to the application from the external world is an API-Gateway, this way we use a lot of API-gateway
# already given features like easy integration and authentication
module "api_gateway" {
  source                                    = "../api-gateway"
  region                                    = var.region
  vcp_link_subnet_1_id                      = var.vcp_link_subnet_1_id
  vcp_link_subnet_2_id                      = var.vcp_link_subnet_2_id
  vcp_link_subnet_3_id                      = var.vcp_link_subnet_3_id
  vpc_link_security_group_id                = aws_security_group.all_all_in_from_inside_vpc.id
  api_gateway_integration_load_balancer_arn = module.rest_api_alb_london.elb_http_listener_arn
  api_gateway_zone_id                       = data.aws_route53_zone.roberto_practice_zone.zone_id
  domain_name                               = var.domain_name
}

# Only create an alias on the domain name if the Load balancer is internet facing
resource "aws_route53_record" "alb_alias" {
  zone_id = data.aws_route53_zone.roberto_practice_zone.zone_id
  name    = var.domain_name
  # A is for Alias
  count = var.rest_api_internal_load_balancer ? 0 : 1
  type  = "A"
  alias {
    name                   = module.rest_api_alb_london.alb_dns_name
    zone_id                = module.rest_api_alb_london.zone_id
    evaluate_target_health = false
  }
}
