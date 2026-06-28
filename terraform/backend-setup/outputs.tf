output "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "backend_config" {
  description = "Backend configuration to add to your main Terraform config"
  value       = <<-EOT
    Add this to your terraform block in main.tf:
    
    backend "s3" {
      bucket  = "${aws_s3_bucket.terraform_state.id}"
      key     = "terraform.tfstate"
      region  = "${var.aws_region}"
      encrypt = true
      
      # S3 native state locking (no DynamoDB needed)
      use_lockfile = true
    }
  EOT
}
