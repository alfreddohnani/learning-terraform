provider "aws" {
  region     = "us-east-2"
  access_key = var.access_key
  secret_key = var.secret_key
}

variable "vpc_cidr_block" {}
variable "subnet_cidr_block" {}
variable "avail_zone" {}
variable "env_prefix" {}
variable "access_key" {}
variable "secret_key" {}
variable "my_ip" {}
variable "instance_type" {}
variable "my_public_ssh_key_location" {}

output "ec2_public_ip" {
  value = aws_instance.myapp-server.public_ip
}

resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block # range of IP addresses. The lower the last number, the more IP addresses in the range
  tags = {
    Name : "${var.env_prefix}-vpc",
  }
}

resource "aws_subnet" "myapp-subnet-1" {
  vpc_id            = aws_vpc.myapp-vpc.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name : "${var.env_prefix}-subnet-1"
  }
}

resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id
  tags = {
    Name : "${var.env_prefix}-igw"
  }
}

resource "aws_route_table" "myapp-route-table" {
  vpc_id = aws_vpc.myapp-vpc.id
  #N.B The internal route is created by default on AWS so we just need to create the internet gateway here.
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }
  tags = {
    Name : "${var.env_prefix}-rtb"
  }
}

resource "aws_route_table_association" "a-rtb-subnet" {
  subnet_id      = aws_subnet.myapp-subnet-1.id
  route_table_id = aws_route_table.myapp-route-table.id
}

resource "aws_security_group" "myapp-sg" {
  name   = "myapp-sg"
  vpc_id = aws_vpc.myapp-vpc.id

  #incoming traffic rules

  # for SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # for browsers
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #exiting traffic rules
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name : "${var.env_prefix}-rtb"
  }
}


data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


resource "aws_key_pair" "ssh-key" {
  key_name   = "server-key"
  public_key = file(var.my_public_ssh_key_location)
}

resource "aws_instance" "myapp-server" {
  ami                    = data.aws_ami.latest-amazon-linux-image.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_security_group.myapp-sg.id]
  availability_zone      = var.avail_zone
  #for SSH
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ssh-key.key_name

  user_data = file("entry-script.sh")

  tags = {
    Name = "${var.env_prefix}-server"
  }
}


data "aws_vpc" "existing_vpc" {
  default = true # accessed with data.aws_vpc.existing_vpc
}
