terraform {
 
  backend "s3" {
    bucket         = "tf-state-jrios"
    key            = "devops/jenkins/orquestrator/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "jenkins-state-locking"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
  default_tags {
    tags = {
      Service = "jenkinsMaster"
    }
  }
}

resource "aws_instance" "jenkinsMaster" {
  ami             = "ami-0892d3c7ee96c0bf7" # Ubuntu 20.04 LTS // us-east-1
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.allow_lisp_ports.name]
  key_name = "jenkinsKey"
}

data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnet_ids" "default_subnet" {
  vpc_id = data.aws_vpc.default_vpc.id
}

resource "aws_security_group" "allow_lisp_ports" {
    name = "security-group.jenkins"
    description = "open ports for jenkins functionality"

    ingress{
        from_port = 50000
        to_port = 50000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress{
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress{
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress{
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "jenkinsKey" {
  key_name   = "jenkinsKey"      
  public_key = tls_private_key.pk.public_key_openssh

  provisioner "local-exec" { 
    command = "rm -rf ~/.ssh/jenkinsKey.pem && echo '${tls_private_key.pk.private_key_pem}' > ~/.ssh/jenkinsKey.pem && chmod 400 ~/.ssh/jenkinsKey.pem"
  }
}