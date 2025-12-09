# environments/webserver-single/variables.tf

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "demo"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "server_message" {
  description = "Message to display on the web page"
  type        = string
  default     = "WebServer Single - Deploy via Jenkins Pipeline"
}