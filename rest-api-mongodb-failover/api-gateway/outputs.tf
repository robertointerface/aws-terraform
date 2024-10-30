output "api_gateway_domain_name" {
  value = aws_apigatewayv2_domain_name.ecommerce_api_gateway_domain_name.domain_name
}
output "api_gateway_target_domain_name"{
  value = aws_apigatewayv2_domain_name.ecommerce_api_gateway_domain_name.domain_name_configuration[0].target_domain_name
}
output "api_gateway_zone_id" {
  value = aws_apigatewayv2_domain_name.ecommerce_api_gateway_domain_name.domain_name_configuration[0].hosted_zone_id
}
output "api_gateway_id" {
  value = aws_apigatewayv2_api.ecommerce_api_gateway.id
}