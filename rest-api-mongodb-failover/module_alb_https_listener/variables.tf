variable "load_balancer_arn" {
  type = string
}
variable "target_group_arn" {
  type = string
}
variable "domain_name" {
  type = string
}
variable "hosted_zone_name" {
  type = string
}
variable "region" {
  type = string
  default = "eu-west-2"
}