# environments/webserver-single/outputs.tf

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = module.webserver.instance_ids[0]
}

output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = module.webserver.public_ips[0]
}

output "private_ip" {
  description = "Private IP of the EC2 instance"
  value       = module.webserver.private_ips[0]
}

output "security_group_id" {
  description = "ID of the security group"
  value       = module.webserver_sg.security_group_id
}

output "website_url" {
  description = "URL to access the website"
  value       = "http://${module.webserver.public_ips[0]}"
}
