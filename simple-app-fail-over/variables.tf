variable "domain_name" {
  type = string
}
variable "hosted_zone_name" {
  type = string
}
variable "vpc_cidr_region_1" {
  type = string
  default = "10.1.0.0/16"
}
variable "vpc_cidr_region_1_submask" {
  type = number
  default = 20
}
variable "vpc_cidr_region_1_subnet_increase" {
  type = number
  default = 16
}
variable "vpc_cidr_region_2" {
  type = string
  default = "10.1.0.0/16"
}
variable "vpc_cidr_region_2_submask" {
  type = number
  default = 20
}
variable "vpc_cidr_region_2_subnet_increase" {
  type = number
  default = 16
}
variable "instance_ami_region_1" {
  type = string
  default =  "ami-0b31d93fb777b6ae6" # Amazon Linux
}
variable "instance_ami_region_2" {
  type = string
  default = "ami-0fa8fe6f147dc938b" # Amazon Linux
}
