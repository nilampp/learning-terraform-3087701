data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["979382823631"] # Bitnami
}

data "aws_vpc" "default"{
  default = true
}

resource "aws_instance" "blog" {
  ami           = data.aws_ami.app_ami.id
  instance_type = "t3.nano"

 vpc_security_group_ids = [aws_security_group.blog.id]

  tags = {
    Name = "Learning Terraform"
  }
}

resource "aws_security_group" "blog"{
  name        = "blog"
  description = "Allow HTTP and HTTPS in. Allow everything out"
  vpc_id      =  data.aws_vpc.default.id
}

resource "aws_security_group_rule" "rule_http_in"{
  type        = "ingress"
  from_port   = 443 
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.security_group.id
}

resource "aws_security_group_rule" "rule_http_everything_out"{
  type        = "egress"
  from_port   = 0 
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.security_group.id
}