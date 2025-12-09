# environments/webserver-single/main.tf
# Deploy de uma única EC2 com WebServer Apache

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend S3 (descomentar para uso em produção)
  # backend "s3" {
  #   bucket         = "terraform-state-bucket"
  #   key            = "webserver-single/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "terraform-demo"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Pipeline    = "Jenkins"
    }
  }
}

# Usa VPC default para simplicidade
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security Group para WebServer
module "webserver_sg" {
  source = "../../modules/security-group"

  name        = "webserver"
  description = "Security group for web server"
  vpc_id      = data.aws_vpc.default.id
  environment = var.environment

  ingress_rules = [
    {
      description = "HTTP"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "HTTPS"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.ssh_allowed_cidr]
    }
  ]

  tags = var.tags
}

# EC2 WebServer
module "webserver" {
  source = "../../modules/ec2"

  name               = "webserver"
  environment        = var.environment
  instance_count     = 1
  instance_type      = var.instance_type
  key_name           = var.key_name
  subnet_id          = data.aws_subnets.default.ids[0]
  security_group_ids = [module.webserver_sg.security_group_id]

  server_colors  = [var.server_color]
  server_message = var.server_message

  tags = var.tags
}