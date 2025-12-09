# main.tf - Deploy de uma única EC2 com WebServer Apache (Simplificado)

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
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

# AMI Amazon Linux 2023 mais recente
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# VPC Default
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security Group
resource "aws_security_group" "webserver" {
  name        = "webserver-${var.environment}-sg"
  description = "Security group for web server demo"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "webserver-${var.environment}-sg"
  }
}

# EC2 Instance
resource "aws_instance" "webserver" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.webserver.id]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    
    cat > /var/www/html/index.html <<HTML
    <!DOCTYPE html>
    <html>
    <head>
      <title>Terraform Demo</title>
      <style>
        body { font-family: Arial; text-align: center; padding: 50px; background: #1a1a2e; color: #eee; }
        .container { background: #16213e; padding: 40px; border-radius: 10px; display: inline-block; }
        h1 { color: #e94560; }
        .info { background: #0f3460; padding: 15px; border-radius: 5px; margin: 10px 0; }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>🚀 ${var.server_message}</h1>
        <div class="info"><strong>Instance ID:</strong> \$(curl -s http://169.254.169.254/latest/meta-data/instance-id)</div>
        <div class="info"><strong>Availability Zone:</strong> \$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</div>
        <div class="info"><strong>Instance Type:</strong> \$(curl -s http://169.254.169.254/latest/meta-data/instance-type)</div>
        <div class="info"><strong>Deploy Time:</strong> \$(date)</div>
      </div>
    </body>
    </html>
    HTML
  EOF

  tags = {
    Name = "webserver-${var.environment}"
  }
}