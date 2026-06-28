variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "crud-app"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

# ── Networking ────────────────────────────
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of AZs to use"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (Web Tier)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_app_cidrs" {
  description = "CIDR blocks for private app subnets (App Tier)"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "private_db_cidrs" {
  description = "CIDR blocks for private DB subnets (Database Tier)"
  type        = list(string)
  default     = ["10.0.5.0/24", "10.0.6.0/24"]
}

# ── EC2 ───────────────────────────────────
variable "ami_id" {
  description = "Ubuntu AMI ID"
  type        = string
  default     = "ami-01a00762f46d584a1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
  default     = ""
}

# ── ASG ───────────────────────────────────
variable "web_asg_min" {
  type    = number
  default = 1
}
variable "web_asg_max" {
  type    = number
  default = 4
}
variable "web_asg_desired" {
  type    = number
  default = 2
}

variable "app_asg_min" {
  type    = number
  default = 2
}
variable "app_asg_max" {
  type    = number
  default = 4
}
variable "app_asg_desired" {
  type    = number
  default = 2
}

# ── RDS ───────────────────────────────────
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "cruddb"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

# ── Monitoring ────────────────────────────
variable "alarm_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
  default     = ""
}
