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

resource "aws_instance" "web" {
  ami           = data.aws_ami.app_ami.id
  instance_type = var.instance_type

 vpc_security_group_ids = [module.module_security_group.security_group_id]

  tags = {
    Name = "Learning Terraform"
  }
}

module "module_security_group"{
  name    = "module_security_group"
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.1"

  vpc_id = data.aws_vpc.default.id

  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules       = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group" "security_group"{
  name        = "security_group"
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