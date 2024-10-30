variable "london_vpc_id" {
  type = string
}
variable "ireland_vpc_id" {
  type = string
}
variable "london_region_subnets_ids" {
  type = list(string)
}
variable "ireland_region_subnets_ids" {
  type = list(string)
}
variable "document_db_global_cluster_name" {
  type = string
}
variable "domain_name" {
  type = string
}
variable "hosted_zone_name" {
  type = string
}
variable "mongo_db_security_group_id_london_region" {
  type = string
}
variable "mongo_db_security_group_id_ireland_region" {
  type = string
}
variable "mongo_db_cluster_host_london_region" {
  type = string
}
variable "mongo_db_cluster_host_ireland_region" {
  type = string
}
variable "mongo_db_cluster_id_ireland_region" {
  type = string
}