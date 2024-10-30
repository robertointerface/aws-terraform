locals {
  domain_name                    = var.domain_name
  hosted_zone_name               = var.hosted_zone_name
  vpc_id                         = var.london_vpc_id
  private_subnet_1a_id           = var.london_region_subnets_ids[0]
  private_subnet_1b_id           = var.london_region_subnets_ids[1]
  private_subnet_1c_id           = var.london_region_subnets_ids[2]
  london_db_host                 = var.mongo_db_cluster_host_london_region
  london_mongo_security_id       = var.mongo_db_security_group_id_london_region
  vpc_id_ireland                  = var.ireland_vpc_id
  private_subnet_ireland_1a_id    = var.ireland_region_subnets_ids[0]
  private_subnet_ireland_1b_id    = var.ireland_region_subnets_ids[1]
  private_subnet_ireland_1c_id    = var.ireland_region_subnets_ids[2]
  ireland_db_host                 = var.mongo_db_cluster_host_ireland_region
  ireland_mongo_security_id       = var.mongo_db_security_group_id_ireland_region
  internal_load_balancer          = true
}
data "aws_route53_zone" "roberto_practice_zone" {
  name         = local.domain_name
  private_zone = false
}

module "rest_api_london" {
  source                              = "./rest-api"
  region                              = "eu-west-2"
  vpc_id                              = local.vpc_id
  rest_api_internal_load_balancer     = local.internal_load_balancer
  alb_subnet_id_first_option          = local.private_subnet_1a_id
  alb_subnet_id_second_option         = local.private_subnet_1b_id
  domain_name                         = local.domain_name
  hosted_zone_name                    = local.hosted_zone_name
  ecs_service_subnet_id_first_option  = local.private_subnet_1a_id
  ecs_service_subnet_id_second_option = local.private_subnet_1b_id
  document_db_host                    = local.london_db_host
  vcp_link_subnet_1_id                = local.private_subnet_1a_id
  vcp_link_subnet_2_id                = local.private_subnet_1b_id
  vcp_link_subnet_3_id                = local.private_subnet_1c_id
  mongo_db_security_group_id          = local.london_mongo_security_id
}
module "route_53_health_check_alarm" {
  source = "./database-fail-over-alarm"
  region = "us-east-1"
  health_check_id = aws_route53_health_check.health_check_alb_port_443.id
}
resource "aws_route53_health_check" "health_check_alb_port_443" {
  fqdn              = "${module.rest_api_london.api_gateway_id}.execute-api.eu-west-2.amazonaws.com"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/"
  failure_threshold = "2"
  request_interval  = "10"
  tags = {
    Name = "health-check-eu-west-2-port-443"
  }
}
# health check for Primary region, that is London region, health-check goes to api gateway
resource "aws_route53_record" "ecommerce_api_gateway_record_london" {
  name    = "api.${local.domain_name}"
  type    = "A"
  zone_id = data.aws_route53_zone.roberto_practice_zone.zone_id
  alias {
    name                   = module.rest_api_london.api_gateway_target_domain_name
    zone_id                = module.rest_api_london.api_gateway_zone_id
    evaluate_target_health = true
  }
  health_check_id = aws_route53_health_check.health_check_alb_port_443.id
  failover_routing_policy {
    type = "PRIMARY"
  }
  set_identifier = "primary"
}
module "rest_api_ireland" {
  source                              = "./rest-api"
  region                              = "eu-west-1"
  vpc_id                              = local.vpc_id_ireland
  rest_api_internal_load_balancer     = local.internal_load_balancer
  alb_subnet_id_first_option          = local.private_subnet_ireland_1a_id
  alb_subnet_id_second_option         = local.private_subnet_ireland_1b_id
  domain_name                         = local.domain_name
  hosted_zone_name                    = local.hosted_zone_name
  ecs_service_subnet_id_first_option  = local.private_subnet_ireland_1a_id
  ecs_service_subnet_id_second_option = local.private_subnet_ireland_1b_id
  document_db_host                    = local.ireland_db_host
  vcp_link_subnet_1_id                = local.private_subnet_ireland_1a_id
  vcp_link_subnet_2_id                = local.private_subnet_ireland_1b_id
  vcp_link_subnet_3_id                = local.private_subnet_ireland_1c_id
  mongo_db_security_group_id          = local.ireland_mongo_security_id
}
# Health check for api gateway on London region
resource "aws_route53_health_check" "health_check_ireland_api_gateway_port_443" {
  fqdn              = "${module.rest_api_ireland.api_gateway_id}.execute-api.eu-west-1.amazonaws.com"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/"
  failure_threshold = "2"
  request_interval  = "10"

  tags = {
    Name = "health-check-eu-west-1-port-443"
  }
}
# Health check for Ireland region, this is required so when primary region is back in active mode we return traffic
# to primary region
resource "aws_route53_record" "ecommerce_api_gateway_record_ireland" {
  name    = "api.${local.domain_name}"
  type    = "A"
  zone_id = data.aws_route53_zone.roberto_practice_zone.zone_id
  alias {
    name                   = module.rest_api_ireland.api_gateway_target_domain_name
    zone_id                = module.rest_api_ireland.api_gateway_zone_id
    evaluate_target_health = true
  }
  health_check_id = aws_route53_health_check.health_check_ireland_api_gateway_port_443.id
  failover_routing_policy {
    type = "SECONDARY"
  }
  set_identifier = "secondary"
}
# Lambda to perform documentDB fail-over
module "lambda_document_db_fail_over" {
  source = "./lambda_document_db_fail_over/infrastructure"
  region = "eu-west-1"
  lambda_name = "document_db_fail_over"
  global_document_db_cluster_name = var.document_db_global_cluster_name
  lambda_ecr_repository = "document-db-switch-over-lambda"
  sns_topic_name = module.route_53_health_check_alarm.sns_topic_name
  mongo_db_cluster_id_ireland_region = var.mongo_db_cluster_id_ireland_region
}
