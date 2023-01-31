terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.17.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.47.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"

  default_tags {
    tags = {
      Environment   = var.environment
      CreatedBy     = "terraform"
      CreatedByUser = "avi.zurel"
      TerraformRepo = "terraform-eks-cluster"
    }
  }
}

resource "aws_kms_key" "environment" {
  description             = "KMS key for EKS ${var.environment}"
  deletion_window_in_days = 10
}

resource "aws_kms_alias" "environment" {
  name          = "alias/${var.environment}"
  target_key_id = aws_kms_key.environment.key_id
}

module "eks" {
  source = "./modules/eks"

  vpc_id            = data.aws_vpc.selected.id
  subnet_ids        = data.aws_subnets.selected.ids
  cluster_name      = var.cluster_name
  default_disk_size = "100"

  cluster_encryption_config = {
    provider_key_arn = aws_kms_key.environment.arn
    resources        = ["secrets"]
  }

  cluster_version = "1.24"

  region = var.region

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  min_size       = 1
  max_size       = 1
  desired_size   = 1
  instance_types = ["m5.2xlarge"]

  tags = {
    Something = "some"
  }
}
