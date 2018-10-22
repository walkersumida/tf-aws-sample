terraform {
  backend "s3" {}
}

data "terraform_remote_state" "state" {
  backend = "s3"
  workspace = "${terraform.workspace}"
  config {
    bucket  = "${var.developer_bucket}"
    key     = "terraform/terraform.tfstate.aws"
    region  = "${var.aws_region}"
    profile = "${var.profile}"
  }
}

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

##########
# VPC
##########
resource "aws_vpc" "main" {
  cidr_block           = "${var.vpc_ip}"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags {
    Name = "${var.env_name}-VPC"
  }
}

##########
# Subnet
##########
resource "aws_subnet" "public_wp" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${var.subnet_public_wp_ip}"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags {
    Name = "${var.env_name}-Subnet-Public-WP1"
  }
}

##########
# Internet Gateway
##########
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"
  tags {
    Name = "${var.env_name}-GW"
  }
}

##########
# Route Table
##########
resource "aws_route_table" "public_rtb" {
  vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
  tags {
    Name = "${var.env_name}-RTB"
  }
}

resource "aws_route_table_association" "public_rtb_asso_wp" {
  subnet_id      = "${aws_subnet.public_wp.id}"
  route_table_id = "${aws_route_table.public_rtb.id}"
}

##########
# Security Group
#########
resource "aws_security_group" "wp" {
  name        = "${var.env_name}-WP"
  description = "It is a security group on http of main"
  vpc_id      = "${aws_vpc.main.id}"
  tags {
    Name = "${var.env_name}-WP"
  }
}

resource "aws_security_group_rule" "wp_in_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.wp.id}"
}

resource "aws_security_group_rule" "wp_in_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.wp.id}"
}

resource "aws_security_group_rule" "wp_out" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.wp.id}"
}

##########
# key pair
#########
resource "aws_key_pair" "main" {
  key_name   = "${var.key_pair_name}"
  public_key = "${file(var.public_key_path)}"
}

##########
# instance
##########
resource "aws_instance" "wp" {
  ami = "ami-8fbab2f3"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.main.key_name}"
  disable_api_termination = false # TODO: 削除保護(destroyした時にエラー出るので一旦無効)
  vpc_security_group_ids = ["${aws_security_group.wp.id}"]
  subnet_id = "${aws_subnet.public_wp.id}"
  tags {
    Name = "${var.env_name}-WP1"
    Role = "wp"
  }
}
