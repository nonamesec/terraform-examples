terraform {
  required_providers {
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
      CreatedByUser = "<username>"
      TerraformRepo = "remote-engine-aws-ec2"
    }
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = var.name
  public_key = "SSH key here"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "remote_engine_" {
  ami       = data.aws_ami.ubuntu.id
  key_name  = aws_key_pair.deployer.key_name
  subnet_id = element(data.aws_subnets.selected.ids, 0)

  instance_type = "m5.2xlarge"

  vpc_security_group_ids = data.aws_security_groups.selected.ids

  tags = {
    Name = "${var.name}"
  }
  user_data = <<EOF
#!/bin/bash

mkdir -p /opt/noname
cd /opt/noname

wget -O noname.tar.gz "<download package URL here>"
tar -xvf noname.tar.gz

<installaer command here, no sudo>
EOF

  root_block_device {
    volume_size = 250
  }
}
