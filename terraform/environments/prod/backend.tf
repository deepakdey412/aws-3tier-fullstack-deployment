# Uncomment and configure after running backend-setup

terraform {
  backend "s3" {
    bucket  = "aws-3tier-app-940507691983-prod-terraform-state"
    key     = "prod/terraform.tfstate"
    region  = "ap-south-1"
    encrypt = true
    
    # S3 native state locking (no DynamoDB needed)
    use_lockfile = true
  }
}
