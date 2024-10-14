variable "region" {
  type = string
  default = "eu-west-2"
}
variable "vpc_cidr_block" {
  type = string
}
variable "subnet_submask" {
  type = number
}
variable "subnet_increase" {
  type = number
}