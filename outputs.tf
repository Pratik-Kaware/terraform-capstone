output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "ec2_public_ip" {
  description = "Public IP of EC2 instance"
  value       = aws_instance.web.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS of EC2 instance"
  value       = aws_instance.web.public_dns
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "website_url" {
  description = "Website URL"
  value       = "http://${aws_instance.web.public_ip}"
}

output "ssh_connection" {
  description = "SSH connection command"
  value       = "ssh -i terraform-key.pem ec2-user@${aws_instance.web.public_ip}"
}

output "database_password_location" {
  description = "Location of database password in AWS Systems Manager"
  value       = "AWS Systems Manager Parameter: /${var.project_name}/database/password"
}

output "database_connection_from_ec2" {
  description = "Command to connect to database from EC2"
  value       = "mysql -h ${aws_db_instance.main.endpoint} -u ${var.db_username} -p"
}

output "private_key_file" {
  description = "Location of generated private key file"
  value       = "terraform-key.pem (created in current directory)"
}