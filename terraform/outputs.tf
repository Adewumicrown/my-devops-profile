output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = module.ec2.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = module.ec2.public_dns
}

output "ecr_repository_url" {
  description = "Full ECR repository URL"
  value       = module.ecr.repository_url
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = module.cloudwatch.log_group_name
}

output "app_url" {
  description = "URL to access your DevOps profile"
  value       = "http://${module.ec2.public_ip}"
}
