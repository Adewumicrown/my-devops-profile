########################################
# Root outputs
########################################

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = module.ec2.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = module.ec2.public_dns
}

output "app_url" {
  description = "URL to access the deployed HTML application"
  value       = "http://${module.ec2.public_ip}"
}

output "ssh_command" {
  description = "Command to SSH into the instance"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${module.ec2.public_ip}"
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name for the application"
  value       = module.iam.cloudwatch_log_group_name
}
