provider "aws" {
    region = "us-east-2"
    access_key = var.access_key
    secret_key = var.secret_key
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {}
variable access_key {}
variable secret_key {}

resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cidr_block # range of IP addresses. The lower the last number, the more IP addresses in the range
    tags = {
        Name : "${var.env_prefix}-vpc",
    }
}

resource "aws_subnet" "myapp-subnet-1" {
    vpc_id = aws_vpc.myapp-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
        Name: "${var.env_prefix}-subnet-1"
    }
}

data "aws_vpc" "existing_vpc" {
    default = true  # accessed with data.aws_vpc.existing_vpc
}