# NOTE that before this script is run with terrraform plan or apply, a domain must be on route 53. The domain url
# must be provided by the variable "domain_name".
data "aws_route53_zone" "roberto_practice_zone" {
  name         = var.domain_name
  private_zone = false
}
# VPC components located at London Region
module "vpc_london" {
  source          = "./module_vpc"
  region          = "eu-west-2"
  vpc_cidr_block  = var.vpc_cidr_region_1
  subnet_submask  = var.vpc_cidr_region_1_submask
  subnet_increase = var.vpc_cidr_region_1_subnet_increase
}
# Load balancer with EC2s/auto scaling and ALB health check on London
module "alb_london" {
  source                          = "./module_alb"
  region                          = "eu-west-2"
  vpc_id                          = module.vpc_london.vpc_id
  subnet_public_1a_id             = module.vpc_london.public_subnet_a_id
  subnet_public_1b_id             = module.vpc_london.public_subnet_b_id
  subnet_private_1a_id            = module.vpc_london.private_subnet_a_id
  subnet_private_1b_id            = module.vpc_london.private_subnet_b_id
  load_balancer_security_group_id = module.vpc_london.security_group_id_for_load_balancer
  asg_instance_security_group_id  = module.vpc_london.security_group_id_for_ec2_instances
  domain_name                     = var.domain_name
  instance_image_id               = var.instance_ami_region_1
  hosted_zone_name                = var.hosted_zone_name
}
# VPC components located at Ireland Region
module "vpc_ireland" {
  source          = "./module_vpc"
  region          = "eu-west-1"
  vpc_cidr_block  = var.vpc_cidr_region_2
  subnet_submask  = var.vpc_cidr_region_2_submask
  subnet_increase = var.vpc_cidr_region_2_subnet_increase
}
# Load balancer with EC2s/auto scaling and ALB health check on Ireland
module "alb_ireland" {
  source                          = "./module_alb"
  region                          = "eu-west-1"
  vpc_id                          = module.vpc_ireland.vpc_id
  subnet_public_1a_id             = module.vpc_ireland.public_subnet_a_id
  subnet_public_1b_id             = module.vpc_ireland.public_subnet_b_id
  subnet_private_1a_id            = module.vpc_ireland.private_subnet_a_id
  subnet_private_1b_id            = module.vpc_ireland.private_subnet_b_id
  load_balancer_security_group_id = module.vpc_ireland.security_group_id_for_load_balancer
  asg_instance_security_group_id  = module.vpc_ireland.security_group_id_for_ec2_instances
  domain_name                     = var.domain_name
  instance_image_id               = var.instance_ami_region_2
  hosted_zone_name                = var.hosted_zone_name
}
# Alias on hosted Zone to re-direct traffic that comes from public hosted zone into London ALB as they primary source
resource "aws_route53_record" "alb_alias" {
  zone_id = data.aws_route53_zone.roberto_practice_zone.zone_id
  name    = var.domain_name
  # A is for Alias
  type = "A"
  alias {
    name                   = module.alb_london.alb_dns_name
    zone_id                = module.alb_london.zone_id
    evaluate_target_health = true
  }
  health_check_id = module.alb_london.health_check_id_port_443
  failover_routing_policy {
    type = "PRIMARY"
  }
  set_identifier = "primary"
}
# Alias on hosted Zone to re-direct traffic that comes from public hosted zone into Ireland ALB as they Secondary
# Source, that means that traffic is only directed to Ireland if Load balancer is failing on London.
resource "aws_route53_record" "alb_alias_ireland" {
  zone_id = data.aws_route53_zone.roberto_practice_zone.zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = module.alb_ireland.alb_dns_name
    zone_id                = module.alb_ireland.zone_id
    evaluate_target_health = true
  }
  health_check_id = module.alb_ireland.health_check_id_port_443
  failover_routing_policy {
    type = "SECONDARY"
  }
  set_identifier = "secondary"
}