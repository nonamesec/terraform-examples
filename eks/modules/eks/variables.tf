variable "cluster_name" {
  description = "the name you want to give to the cluster"
}

variable "region" {
  description = "AWS Region to place the cluster in"
}

variable "cluster_version" {
  description = "Cluster version for eks/kube"
}

variable "tags" {
  type        = map(string)
  description = "AWS Tags to assign"
}

variable "cluster_endpoint_private_access" {
  type        = bool
  description = "Should we include a private endpoint?"
}

variable "cluster_endpoint_public_access" {
  type        = bool
  description = "Should we include a public endpoint?"
}

variable "vpc_id" {
  description = "The ID of the VPC you want to put this cluster in"
}

variable "subnet_ids" {
  type        = list(string)
  description = "IDS for subnet. Private would be best practice"
}

variable "min_size" {}

variable "max_size" {}

variable "desired_size" {}

variable "instance_types" {
  type = list(string)
}

variable "default_disk_size" {
}

variable "cluster_encryption_config" {
  type = any
}
