variable "london_vpc_id" {
  type        = string
  description = "vpc id of a vpc on the london region, this is the primary region"
}
variable "ireland_vpc_id" {
  type        = string
  description = "vpc id of a vpc on the ireland region, this is the fail-over region"
}
variable "london_region_private_subnets_ids" {
  type        = list(string)
  description = "list of private subnets ids from London region"
}
variable "ireland_region_private_subnets_ids" {
  type        = list(string)
  description = "list of private subnets ids from Ireland region"
}
variable "document_db_global_cluster_name" {
  type        = string
  description = "DocumentDB global cluster name"
}
variable "domain_name" {
  type        = string
  description = "owned domain name that is managed by route 53"
}
variable "hosted_zone_name" {
  type        = string
  description = "name of hosted zone in route 53, this is normally the same as the domain name"
}
variable "mongo_db_security_group_id_london_region" {
  type        = string
  description = <<EOT
  Security group id of the mongo cluster on London region, the reason why is required is because the security group will
  be modified to accept traffic from the ECS cluster where the Rest-api runs.
  EOT
}
variable "mongo_db_security_group_id_ireland_region" {
  type        = string
  description = <<EOT
  Security group id of the mongo cluster on Ireland region, the reason why is required is because the security group will
  be modified to accept traffic from the ECS cluster where the Rest-api runs.
  EOT
}
variable "mongo_db_cluster_endpoint_london_region" {
  type        = string
  description = <<EOT
  DocumentDB cluster endpoint from the London region, required as this is set as an environment variable on the Task
  definition for the ECS task that runs the Rest-API from the London region.
  EOT
}
variable "mongo_db_cluster_endpoint_ireland_region" {
  type        = string
  description = <<EOT
  DocumentDB cluster endpoint from the London region, required as this is set as an environment variable on the Task
  definition for the ECS task that runs the Rest-API from the Ireland region.
  EOT
}
variable "mongo_db_cluster_ARN_ireland_region" {
  type        = string
  description = <<EOT
  DocumentDB Ireland cluster ARN, this is required as we need to create an IAM Policy for the lambda that allows it to
  perform Fail-Over of the DocumentDB global Cluster to the Ireland region
  EOT
}
variable "fail_over_lambda_ecr_repository" {
  type        = string
  description = "Repository where the fail-over lambda image is located."
}
variable "mongo_db_global_cluster_arn" {
  type        = string
  description = "ARN of the documentDB global cluster, is required so the lambda has the necessary permissions."
}
variable "mongo_db_cluster_arn_london_region" {
  type = string
}