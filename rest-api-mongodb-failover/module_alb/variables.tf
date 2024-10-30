variable "region" {
  type = string
  default = "eu-west-2"
}
variable "vpc_id" {
  type = string
}
variable "alb_subnet_id_first_option" {
  type = string
}
variable "alb_subnet_id_second_option" {
  type = string
}
variable "load_balancer_security_group_id" {
  type = string
}
variable "load_balancer_internal" {
  type = bool
  default = false
}