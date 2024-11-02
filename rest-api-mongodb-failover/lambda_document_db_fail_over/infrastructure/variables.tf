
variable "region" {
  type = string
}

variable "lambda_name" {
  type = string
}

variable "global_document_db_cluster_name" {
  type = string
}
variable "sns_topic_name" {
  type = string
}
variable "lambda_ecr_repository" {
  type = string
}
variable "lambda_image_tag" {
  type    = string
  default = "latest"
}
variable "mongo_db_cluster_id_ireland_region" {
  type = string
}
variable "mongo_db_global_cluster_arn" {
  type = string
}
variable "mongo_db_cluster_arn_london_region" {
  type = string
}