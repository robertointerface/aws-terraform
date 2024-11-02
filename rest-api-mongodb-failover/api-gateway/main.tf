#
provider "aws" {
  region = var.region
}
data "aws_security_group" "all_in_all_out" {
  id = var.vpc_link_security_group_id
}
resource "aws_apigatewayv2_vpc_link" "vpc_link" {
  name               = "api-gateway-vpc-link"
  subnet_ids         = [var.vcp_link_subnet_1_id, var.vcp_link_subnet_2_id, var.vcp_link_subnet_3_id] # Replace with your private subnets
  security_group_ids = [data.aws_security_group.all_in_all_out.id]                                    # A security group for the VPC Link
}
# Create the HTTP API-Gateway, note that is HTTP and not Rest-API
resource "aws_apigatewayv2_api" "ecommerce_api_gateway" {
  name          = "ecommerce-http-api"
  protocol_type = "HTTP"
}
# integrate api gateway with the load balancer that is redirecting traffic to ECS cluster
# the integration_uri is the
resource "aws_apigatewayv2_integration" "private_lb_integration" {
  api_id             = aws_apigatewayv2_api.ecommerce_api_gateway.id
  integration_type   = "HTTP_PROXY"
  integration_uri    = var.api_gateway_integration_load_balancer_arn
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.vpc_link.id
  integration_method = "ANY"
}
resource "aws_apigatewayv2_route" "api_route" {
  api_id    = aws_apigatewayv2_api.ecommerce_api_gateway.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.private_lb_integration.id}"
}
resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.ecommerce_api_gateway.id
  name        = "$default"
  auto_deploy = true
}
# Create a certificate for the domain that API-Gateway uses
resource "aws_acm_certificate" "ecommerce_api_certificate" {
  domain_name       = "api.${var.domain_name}"
  validation_method = "DNS"
}
# Validate the created certificate
resource "aws_route53_record" "ecommerce_api_validation_records" {
  for_each = {
    for dvo in aws_acm_certificate.ecommerce_api_certificate.domain_validation_options : dvo.domain_name => {
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
  zone_id         = var.api_gateway_zone_id
}
resource "aws_acm_certificate_validation" "ecommerce_api_validation" {
  certificate_arn         = aws_acm_certificate.ecommerce_api_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.ecommerce_api_validation_records : record.fqdn]
}
resource "aws_apigatewayv2_domain_name" "ecommerce_api_gateway_domain_name" {
  domain_name = "api.${var.domain_name}"
  domain_name_configuration {
    certificate_arn = aws_acm_certificate_validation.ecommerce_api_validation.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}
resource "aws_apigatewayv2_api_mapping" "ecommerce_to_api_domain" {
  api_id      = aws_apigatewayv2_api.ecommerce_api_gateway.id
  stage       = aws_apigatewayv2_stage.default_stage.id
  domain_name = aws_apigatewayv2_domain_name.ecommerce_api_gateway_domain_name.id
}

