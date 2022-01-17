provider "aws" {
  region     = "us-east-2"
  access_key = var.access_key
  secret_key = var.secret_key
}



resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block # range of IP addresses. The lower the last number, the more IP addresses in the range
  tags = {
    Name : "${var.env_prefix}-vpc",
  }
}

module "myapp-subnet" {
  source            = "./modules/subnet"
  subnet_cidr_block = var.subnet_cidr_block
  avail_zone        = var.avail_zone
  env_prefix        = var.env_prefix
  vpc_id            = aws_vpc.myapp-vpc.id
}

module "myapp-server" {
  source                     = "./modules/webserver"
  vpc_id                     = aws_vpc.myapp-vpc.id
  my_ip                      = var.my_ip
  env_prefix                 = var.env_prefix
  ami_name                   = var.ami_name
  my_public_ssh_key_location = var.my_public_ssh_key_location
  instance_type              = var.instance_type
  subnet_id                  = module.myapp-subnet.subnet.id
  avail_zone                 = var.avail_zone

}
data "aws_vpc" "existing_vpc" {
  default = true # accessed with data.aws_vpc.existing_vpc
}
