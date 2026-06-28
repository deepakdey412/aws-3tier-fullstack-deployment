output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "web_alb_dns_name" {
  description = "DNS name of the internet-facing ALB (Web Tier)"
  value       = module.web_alb.alb_dns_name
}

output "app_alb_dns_name" {
  description = "DNS name of the internal ALB (App Tier)"
  value       = module.app_alb.alb_dns_name
}

output "rds_endpoint" {
  description = "RDS MySQL endpoint"
  value       = module.rds.db_endpoint
  sensitive   = true
}

output "s3_bucket_name" {
  description = "S3 bucket for logs and backups"
  value       = module.s3.bucket_id
}

output "web_asg_name" {
  description = "Web Tier ASG name"
  value       = module.web_asg.asg_name
}

output "app_asg_name" {
  description = "App Tier ASG name"
  value       = module.app_asg.asg_name
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_app_subnet_ids" {
  value = module.vpc.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  value = module.vpc.private_db_subnet_ids
}

output "cloudwatch_dashboard_url" {
  value = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${module.cloudwatch.dashboard_name}"
}
