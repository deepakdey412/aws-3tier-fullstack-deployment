variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "db_subnet_group_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_instance_class" {
  type = string
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "s3_bucket_arn" {
  type = string
}

variable "iam_role_arn" {
  type = string
}