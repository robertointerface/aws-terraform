variable "region" {
  type = string
  default = "eu-west-2"
}
variable "vpc_id" {
  type = string
}
variable "ecs_service_subnet_first_option" {
  type = string
}
variable "ecs_service_subnet_second_option" {
  type = string
}
variable "mongo_db_security_group_id" {
  type = string
}
variable "load_balancer_security_group_id" {
  type = string
}
variable "ecr_repository_ecommerce_rest_api" {
  type = string
}
variable "ecr_tag_ecommerce_rest_api" {
  type = string
}
variable "mongo_cluster_password_secret_name" {
  type = string
}
variable "fargate_target_group_name" {
  type = string
}
variable "fargate_target_group_arn" {
  type = string
}
variable "task_IAM_role_name" {
  type = string
}
variable "load_balancer_name" {
  type = string
}
variable "load_balancer_arn" {
  type = string
}
variable "db_host" {
  type = string
}
