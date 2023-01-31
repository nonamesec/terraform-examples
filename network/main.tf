terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.45.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"

  default_tags {
    tags = {
      Environment   = var.environment
      CreatedBy     = "terraform"
      TerraformRepo = "terraform-network"
    }
  }
}

# Setting up an elastic IP. 
# This Elastic IP is attached to the nat gateway so you have a single external IP address coming out of your environment
resource "aws_eip" "nat" {
  count = 1
  vpc   = true
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> v2.0"

  name = var.environment

  # CIDR and subnet definitions
  cidr             = "10.${var.account_octet}.0.0/16"
  azs              = ["${var.region}a", "${var.region}b"]
  database_subnets = ["10.${var.account_octet}.160.0/19", "10.${var.account_octet}.192.0/19"]
  private_subnets  = ["10.${var.account_octet}.64.0/19", "10.${var.account_octet}.96.0/19"]
  public_subnets   = ["10.${var.account_octet}.0.0/20", "10.${var.account_octet}.16.0/20"]

  # Single NAT gateway
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  reuse_nat_ips          = true
  external_nat_ip_ids    = aws_eip.nat.*.id

  enable_vpn_gateway = true

  enable_s3_endpoint = true

  # these are both required for the private_dns_enabled options on the endpoints below
  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_lambda_endpoint              = true
  lambda_endpoint_private_dns_enabled = true
  lambda_endpoint_security_group_ids  = [aws_security_group.default.id]

  enable_kms_endpoint              = true
  kms_endpoint_private_dns_enabled = true
  kms_endpoint_security_group_ids  = [aws_security_group.default.id]

  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60
}

resource "aws_security_group" "private" {
  depends_on = [module.vpc]

  name        = "private"
  description = "Allow everything in private"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "private"
  }
}

resource "aws_security_group_rule" "private_to_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.private.id
  description       = "Rule set by Terraform"
}

resource "aws_security_group_rule" "private_to_alb_ingress" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.private.id
  source_security_group_id = aws_security_group.private_alb.id
  description              = "Rule set by Terraform"
}

# The AWS Security Group is open to all egress.
# We encourage you to set boundaries via Kube network security resources
resource "aws_security_group_rule" "private_to_all_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.private.id
  description       = "Rule set by Terraform"
}

resource "aws_security_group" "private_alb" {
  depends_on = [module.vpc]

  name        = "private-alb"
  description = "Allow 443 access from private sg"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "private-alb"
  }
}

resource "aws_security_group_rule" "https_to_private_alb" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "TCP"
  cidr_blocks       = ["10.0.0.0/8"]
  security_group_id = aws_security_group.private_alb.id
  description       = "Rule set by Terraform"
}

resource "aws_security_group_rule" "private_to_alb" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "TCP"
  security_group_id        = aws_security_group.private_alb.id
  source_security_group_id = aws_security_group.private.id
  description              = "Rule set by Terraform"
}

# public ALB group
# rules:
# inbound: 443 from public, 443 from 10.0.0.0/8
# outbound: all to public-alb, all to public
resource "aws_security_group" "public_alb" {
  depends_on = [module.vpc]

  name        = "public-alb"
  description = "Allow 443 access from public sg"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "public-alb"
  }
}

resource "aws_security_group_rule" "https_to_public_alb" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.public_alb.id
  description       = "Rule set by Terraform"
}

resource "aws_security_group_rule" "http_to_public_alb" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.public_alb.id
  description       = "Rule set by Terraform"
}

resource "aws_security_group_rule" "public_to_alb_ingress" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.private.id
  source_security_group_id = aws_security_group.public_alb.id
  description              = "Rule set by Terraform"
}

resource "aws_security_group_rule" "public_alb_to_private" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.public_alb.id
  source_security_group_id = aws_security_group.private.id
  description              = "Rule set by Terraform"
}

resource "aws_security_group_rule" "public_alb_to_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.public_alb.id
  description       = "Rule set by Terraform"
}

