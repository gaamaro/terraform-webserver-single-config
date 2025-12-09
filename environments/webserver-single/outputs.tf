# environments/webserver-single/outputs.tf

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.webserver.id
}

output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.webserver.public_ip
}

output "private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.webserver.private_ip
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.webserver.id
}

output "website_url" {
  description = "URL to access the website"
  value       = "http://${aws_instance.webserver.public_ip}"
}