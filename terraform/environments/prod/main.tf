terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# ──────────────────────────────────────────
# VPC
# ──────────────────────────────────────────
module "vpc" {
  source = "../../modules/vpc"

  project_name        = var.project_name
  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  private_app_cidrs   = var.private_app_cidrs
  private_db_cidrs    = var.private_db_cidrs
  availability_zones  = var.availability_zones
}

# ──────────────────────────────────────────
# S3 (logs & backups)
# ──────────────────────────────────────────
module "s3" {
  source = "../../modules/s3"

  project_name = var.project_name
  environment  = var.environment
}

# ──────────────────────────────────────────
# IAM
# ──────────────────────────────────────────
module "iam" {
  source = "../../modules/iam"

  project_name    = var.project_name
  environment     = var.environment
  s3_bucket_arn   = module.s3.bucket_arn
}

# ──────────────────────────────────────────
# Security Groups
# ──────────────────────────────────────────
module "security_groups" {
  source = "../../modules/security-groups"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
}

# ──────────────────────────────────────────
# ALB – Internet-facing (Web Tier)
# ──────────────────────────────────────────
module "web_alb" {
  source = "../../modules/alb"

  name               = "${var.project_name}-web-alb"
  internal           = false
  security_group_ids = [module.security_groups.alb_sg_id]
  subnet_ids         = module.vpc.public_subnet_ids
  vpc_id             = module.vpc.vpc_id
  target_port        = 80
  health_check_path  = "/health"
  environment        = var.environment
  project_name       = var.project_name
  alb_type           = "web"
  s3_bucket_id       = module.s3.bucket_id
  s3_bucket_arn      = module.s3.bucket_arn
}

# ──────────────────────────────────────────
# ALB – Internal (App Tier)
# ──────────────────────────────────────────
module "app_alb" {
  source = "../../modules/alb"

  name               = "${var.project_name}-app-alb"
  internal           = true
  security_group_ids = [module.security_groups.app_sg_id]
  subnet_ids         = module.vpc.private_app_subnet_ids
  vpc_id             = module.vpc.vpc_id
  target_port        = 8080
  health_check_path  = "/api/health"
  environment        = var.environment
  project_name       = var.project_name
  alb_type           = "app"
  s3_bucket_id       = module.s3.bucket_id
  s3_bucket_arn      = module.s3.bucket_arn
}

# ──────────────────────────────────────────
# ASG – Web Tier
# ──────────────────────────────────────────
module "web_asg" {
  source = "../../modules/asg"

  name                   = "${var.project_name}-web"
  ami_id                 = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  security_group_ids     = [module.security_groups.web_sg_id]
  subnet_ids             = module.vpc.public_subnet_ids
  target_group_arns      = [module.web_alb.target_group_arn]
  iam_instance_profile   = module.iam.ec2_instance_profile_name
  min_size               = var.web_asg_min
  max_size               = var.web_asg_max
  desired_capacity       = var.web_asg_desired
  user_data              = base64encode(templatefile("${path.module}/templates/web-userdata.sh.tpl", {
    app_alb_dns  = module.app_alb.alb_dns_name
    s3_bucket    = module.s3.bucket_id
    project_name = var.project_name
    environment  = var.environment
  }))
  environment            = var.environment
  project_name           = var.project_name
  tier                   = "web"
}

# ──────────────────────────────────────────
# ASG – App Tier
# ──────────────────────────────────────────
module "app_asg" {
  source = "../../modules/asg"

  name                   = "${var.project_name}-app"
  ami_id                 = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  security_group_ids     = [module.security_groups.app_sg_id]
  subnet_ids             = module.vpc.private_app_subnet_ids
  target_group_arns      = [module.app_alb.target_group_arn]
  iam_instance_profile   = module.iam.ec2_instance_profile_name
  min_size               = var.app_asg_min
  max_size               = var.app_asg_max
  desired_capacity       = var.app_asg_desired
  user_data              = base64encode(templatefile("${path.module}/templates/app-userdata.sh.tpl", {
    db_endpoint  = module.rds.db_address
    db_name      = var.db_name
    db_username  = var.db_username
    db_password  = var.db_password
    s3_bucket    = module.s3.bucket_id
    aws_region   = var.aws_region
    project_name = var.project_name
    environment  = var.environment
  }))
  environment            = var.environment
  project_name           = var.project_name
  tier                   = "app"
}

# ──────────────────────────────────────────
# ──────────────────────────────────────────
# RDS MySQL Single-AZ with Automated Backups
# ──────────────────────────────────────────
module "rds" {
  source = "../../modules/rds"

  project_name        = var.project_name
  environment         = var.environment
  db_subnet_group_ids = module.vpc.private_db_subnet_ids
  security_group_ids  = [module.security_groups.db_sg_id]
  db_name             = var.db_name
  db_username         = var.db_username
  db_password         = var.db_password
  db_instance_class   = var.db_instance_class
  multi_az            = false  # Single-AZ (free tier)
  s3_bucket_arn       = module.s3.bucket_arn
  iam_role_arn        = module.iam.rds_role_arn
}

# ──────────────────────────────────────────
# CloudWatch
# ──────────────────────────────────────────
module "cloudwatch" {
  source = "../../modules/cloudwatch"

  project_name     = var.project_name
  environment      = var.environment
  aws_region       = var.aws_region
  web_asg_name     = module.web_asg.asg_name
  app_asg_name     = module.app_asg.asg_name
  web_alb_arn      = module.web_alb.alb_arn
  app_alb_arn      = module.app_alb.alb_arn
  rds_identifier   = module.rds.db_identifier
  s3_bucket_id     = module.s3.bucket_id
  alarm_email      = var.alarm_email
}
