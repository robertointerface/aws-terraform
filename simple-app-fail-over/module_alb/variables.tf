variable "region" {
  type = string
  default = "eu-west-2"
}
variable "hosted_zone_name" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "subnet_public_1a_id" {
  type = string
}
variable "subnet_public_1b_id" {
  type = string
}
variable "subnet_private_1a_id" {
  type = string
}
variable "subnet_private_1b_id" {
  type = string
}
variable "load_balancer_security_group_id" {
  type = string
}
variable "asg_instance_security_group_id" {
  type = string
}
variable "domain_name" {
  type = string
}
variable "instance_image_id" {
  type = string
}