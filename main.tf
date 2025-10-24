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

module "module_dev_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "dev_vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.app_ami.id
  instance_type = var.instance_type

 vpc_security_group_ids = [module.module_security_group.security_group_id]

 subnet_id = module.module_dev_vpc.public_subnets[0]

  tags = {
    Name = "Learning Terraform"
  }
}

module "alb" {
  source            = "terraform-aws-modules/alb/aws"
  load_balancer_type ="application"

  name            = "dev-alb"
  vpc_id          = module.module_dev_vpc.vpc_id
  subnets         = module.module_dev_vpc.public_subnets
  security_groups = [module.module_security_group.security_group_id]

  listeners = {
    http-tcs-listeners = {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  }

  target_groups = [
    {
      name_prefix      = "blog"
      protocol         = "HTTP"
      port             = 80
      target_type      = "instance"
      targets ={
        my_target ={
          target_id        = aws_instance.web.id
          port             = 80
        }
      } 
    }
  ] 

  tags = {
    Environment = "dev"
  }
}

module "module_security_group"{
  name    = "module_security_group"
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.1"

  vpc_id = module.module_dev_vpc.vpc_id

  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules       = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}
