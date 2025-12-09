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
  default     = "t2.micro"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = ""
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed for SSH access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "server_color" {
  description = "Color theme for the server (blue, green, red, yellow)"
  type        = string
  default     = "blue"
}

variable "server_message" {
  description = "Message to display on the web page"
  type        = string
  default     = "WebServer Single - Deploy via Jenkins Pipeline"
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
