output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.startuptech_vpc.id
}

output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = aws_lb.app_alb.dns_name
}

output "bastion_public_ip" {
  description = "Public (Elastic) IP of the Bastion host"
  value       = aws_eip.bastion_eip.public_ip
}

output "backend_private_ip" {
  description = "Private IP of the Backend server"
  value       = aws_instance.backend.private_ip
}

output "mongodb_private_ip" {
  description = "Private IP of the MongoDB server"
  value       = aws_instance.mongodb.private_ip
}

output "ssh_private_key_path" {
  description = "Path to the generated private key used for SSH access"
  value       = local_file.private_key.filename
}

output "ssh_to_bastion_command" {
  description = "Ready-to-use command to SSH into the Bastion host"
  value       = "ssh -i ${local_file.private_key.filename} ec2-user@${aws_eip.bastion_eip.public_ip}"
}