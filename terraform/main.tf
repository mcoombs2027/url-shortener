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
  iam_instance_profile = "${aws_iam_instance_profile.url-shortener-profile.name}"
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
echo "export FLASK_APP=routes" >> /etc/bashrc
echo "export FLASK_ENVIRONMENT=production" >> /etc/bashrc
yum update -y
yum -y install jq pip3
ec2_reg=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -c -r .region)
mkdir -p /opt/url-shortener/app
aws --region $ec2_reg s3 cp s3://${var.bucket}/main.py /opt/url-shortener/
aws --region $ec2_reg s3 cp s3://${var.bucket}/app/ /opt/url-shortener/app/ --recursive
aws --region $ec2_reg s3 cp s3://${var.bucket}/app/templates/ /opt/url-shortener/app/templates/ --recursive
aws --region $ec2_reg s3 cp s3://${var.bucket}/flask.service /usr/lib/systemd/system/
pip3 install flask click Flask-Migrate Flask-SQLAlchemy hashids config
source /etc/bashrc
cd /opt/url-shortener/app
chmod 755 *.py *.sh
flask db init
flask db migrate
flask db upgrade
ln -s /usr/lib/systemd/system/flask.service /etc/systemd/system/multi-user.target.wants/
systemctl daemon-reload
systemctl enable flask.service
systemctl start flask
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

  ingress {
    from_port = 5000
    protocol = "tcp"
    to_port = 5000
    cidr_blocks = local.home
  }

  ingress {
    from_port = -1
    protocol = "ICMP"
    to_port = -1
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

resource "aws_iam_role" "url-shortener" {
  name        = "${var.name}"
  description = "${var.name} instance role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "url-shortener-profile" {
  name = "${var.name}"
  role = "${aws_iam_role.url-shortener.name}"
}

resource "aws_iam_policy" "url-shortener-bucket-readonly" {
  name = "${var.name}-url-shortener-bucket-readonly"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1425916919000",
            "Effect": "Allow",
            "Action": [
                "s3:List*",
                "s3:Get*"
            ],
            "Resource": [
                "arn:aws:s3:::${var.bucket}",
                "arn:aws:s3:::${var.bucket}/*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "url-shortener-bucket-readonly" {
  role       = "${aws_iam_role.url-shortener.name}"
  policy_arn = "${aws_iam_policy.url-shortener-bucket-readonly.arn}"
}