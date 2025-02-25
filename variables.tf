variable "aws_region" {
  type = string
}
variable "aws_db_vpc_id" {
  type = string
}
variable "aws_db_subnet_ids" {
  type = list(string)
}
variable "aws_db_subnet_zones" {
  type = list(string) # Example - ["use1-az1", "use1-az2", "use1-az6"]
}
variable "aws_rds_mysql_instance_name" {
  type = string
}
variable "aws_rds_mysql_db" {
  type = string
}
variable "aws_rds_mysql_tables" {
  type = list(string)
}
variable "aws_rds_mysql_user" {
  type = string
}
variable "aws_rds_mysql_password" {
  type = string
}
variable "cc_cloud_api_key" {
  type = string
}
variable "cc_cloud_api_secret" {
  type = string
}
variable "cc_env" {
  type = string
}
variable "cc_kafka_cluster_name" {
  type = string
}
variable "cc_kafka_cluster_type" {
  type = string
  default = "enterprise"
}
variable "cc_kafka_create_cluster" {
  type = bool
  default = true
}
variable "cc_network_name" {
  type = string
}
variable "cc_create_network" {
  type = bool
  default = true
}
variable "cc_create_ops_service_account" {
  type = bool
  default = true
}
variable "gcp_project_id" {
  type = string
}
variable "gcp_bigquery_dataset" {
  type = string
}
variable "gcp_bq_service_account_name" {
  type = string
}
variable "gcp_bq_service_account_json_file" {
  type = string
}