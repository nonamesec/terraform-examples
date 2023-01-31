resource "aws_security_group" "default" {
  name   = "${var.environment}-vpc-resources"
  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group_rule" "default_to_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.default.id
  description       = "Rule set by Terraform"
}

resource "aws_security_group_rule" "endpoint_subnets_to_default" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = module.vpc.private_subnets_cidr_blocks
  security_group_id = aws_security_group.default.id
  description       = "Rule set by Terraform"
}

resource "aws_security_group_rule" "default_to_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.default.id
  description       = "Rule set by Terraform"
}
