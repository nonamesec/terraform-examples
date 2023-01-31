variable "account_octet" {
  description = "Second part of the CIDR 10.{octet}.0.0"
}

variable "region" {
  description = "AWS region"
}

variable "environment" {
  description = "The name of the enviornment to create (Will be the name of the VPC)"
}

variable "cluster_name" {
  description = "Cluster name you want to create"
}
