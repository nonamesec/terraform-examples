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
    name = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  filter {
    name = "tag:Name"
    values = [
      "${var.environment}-private-${var.region}a",
      "${var.environment}-private-${var.region}b"
    ]
  }
}

data "aws_security_group" "selected" {
  name = "private"
}
