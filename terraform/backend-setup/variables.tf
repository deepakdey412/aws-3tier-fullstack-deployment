variable "aws_region" {
  description = "AWS region for backend resources"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "aws-3tier-app-project"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}
