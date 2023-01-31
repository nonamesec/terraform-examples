data "aws_vpc" "selected" {
  filter {
    name = "tag:Name"
    values = [
      var.environment
    ]
  }
}

data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  filter {
    name = "tag:Name"
    values = [
      "${var.environment}-public-${var.region}a",
      "${var.environment}-public-${var.region}b"
    ]
  }
}

data "aws_security_groups" "selected" {
  filter {
    name   = "group-name"
    values = ["*public*"]
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}
