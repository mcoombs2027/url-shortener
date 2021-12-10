terraform {
  required_version = ">= 1.0.2"

  // Administrative S3 bucket to serve as centralized store for infra and configs
  backend "s3" {
    key = "terraform/us-infra.state"
    bucket = "url-config"

    // Assume administrative s3 backend defined in infra.auto.tfvars
    // region = administrative s3 region
    // bucket = administrative s3 bucket name
  }
}

provider "aws" {
  region = "us-east-1"
}

// Create ec2 host for flask, python, etc
resource "aws_instance" "flask-web" {
  ami = var.image_id
  instance_type = var.instance_type
  security_groups = [aws_security_group.default.name]
  key_name = var.ec2_keypair
  root_block_device {
    volume_type = "gp3"
    volume_size = "16"
  }

  tags = {
    Name = var.name
  }

  user_data = <<EOF
#!/usr/bin/env bash
export EC2_HOME=/opt/aws/apitools/ec2
export PATH=$PATH:$EC2_HOME/bin
yum update -y
yum -y install jq pip3
pip3 install flask click
shutdown -r now
EOF
}

resource "aws_security_group" "default" {
  name = "${var.name}-sg"
  description = "Allow http traffic"
  vpc_id = var.vpc_id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = local.home
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.home
  }
   egress {
     from_port = 0
     protocol = "-1"
     to_port = 0
     cidr_blocks = ["0.0.0.0/0"]
   }

  tags = {
    Name      = "${var.name}-sg"
  }



}