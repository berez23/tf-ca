provider "aws" {
  region = "us-west-2"

  default_tags {
    tags = {
      h4sec = "ca"
    }
  }
}

module "vpc" {
  source          = "terraform-aws-modules/vpc/aws"
  name            = var.vpc_name
  cidr            = var.vpc_cidr
  azs             = var.vpc_azs
  private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets

  enable_nat_gateway = var.vpc_enable_nat_gateway

  tags = var.vpc_tags
}

module "ec2_instances_bh" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "4.1.4"
  count                  = 1
  key_name               = "ca_ba"
  name                   = "bastian-host"
  ami                    = "ami-0c5204531f799e0c6"
  instance_type          = "t2.micro"
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.vpc_ssh.id]
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "ec2_instances_public" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  version                     = "4.1.4"
  associate_public_ip_address = false
  count                       = 2
  key_name                    = "ca_key"
  name                        = "ngnix-${count.index + 1}"
  ami                         = "ami-0c5204531f799e0c6"
  instance_type               = "t2.micro"
  subnet_id                   = module.vpc.public_subnets[count.index]
  vpc_security_group_ids      = [aws_security_group.vpc_http-https.id]
  root_block_device = [
    {
      encrypted   = true
      volume_size = 50
    },
  ]
}

module "ec2_instances_ca" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "4.1.4"
  count                  = 1
  key_name               = "ca_ba"
  name                   = "CA"
  ami                    = "ami-0c5204531f799e0c6"
  instance_type          = "t2.micro"
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.vpc_ssh.id]
  root_block_device = [
    {
      encrypted   = true
      volume_size = 50
    },
  ]
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "key_pair" {
  source             = "terraform-aws-modules/key-pair/aws"
  key_name           = "ca_ba"
  create_private_key = true
}

module "key_pair_ca" {
  source             = "terraform-aws-modules/key-pair/aws"
  key_name           = "ca_key"
  create_private_key = true
}

resource "aws_security_group" "vpc_ssh" {
  name_prefix = "vpc_ssh"
  description = "Allow ssh inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "ssh from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}

resource "aws_security_group" "vpc_http-https" {
  name_prefix = "vpc_https"
  description = "Allow https inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "http VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "http VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
resource "aws_eip" "eip_manager" {
  instance = element(module.ec2_instances_public.*.id, count.index)
  count    = 2
  vpc      = true

  tags = {
    Name = "eip-ngnix-${count.index + 1}"
  }
}
