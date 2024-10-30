variable "region" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "rest_api_internal_load_balancer" {
  type = bool
}
variable "alb_subnet_id_first_option"{
  type = string
}
variable "alb_subnet_id_second_option"{
  type = string
}
variable "ecs_service_subnet_id_first_option" {
  type = string
}
variable "ecs_service_subnet_id_second_option" {
  type = string
}
variable "document_db_host" {
  type = string
}
variable "vcp_link_subnet_1_id"{
  type = string
}
variable "vcp_link_subnet_2_id"{
  type = string
}
variable "vcp_link_subnet_3_id"{
  type = string
}
variable "mongo_db_security_group_id" {
  type = string
}
variable "domain_name" {
  type = string
}
variable "hosted_zone_name" {
  type = string
}
