variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "web_asg_name" {
  type = string
}

variable "app_asg_name" {
  type = string
}

variable "web_alb_arn" {
  type = string
}

variable "app_alb_arn" {
  type = string
}

variable "rds_identifier" {
  type = string
}

variable "s3_bucket_id" {
  type = string
}

variable "alarm_email" {
  type    = string
  default = ""
}