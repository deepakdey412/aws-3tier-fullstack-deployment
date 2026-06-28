TERRAFORM BACKEND SETUP
=======================

This directory sets up S3 for storing Terraform state remotely with native S3 locking.

STEPS:
------

1. Initialize and apply this backend setup FIRST:
   cd terraform/backend-setup
   terraform init
   terraform apply

2. Note the output (S3 bucket name)

3. Update terraform/environments/prod/backend.tf with the bucket name

4. Uncomment the backend configuration in backend.tf

5. Re-initialize your main terraform:
   cd ../environments/prod
   terraform init -migrate-state

6. Answer "yes" when prompted to migrate state to S3

BENEFITS:
---------
- Remote state storage in S3 (secure, versioned, encrypted)
- Native S3 state locking (no DynamoDB needed - cost savings!)
- Team collaboration (multiple people can work on same infrastructure)
- State backup and recovery with S3 versioning

WHAT'S NEW:
-----------
- AWS S3 now provides NATIVE state locking
- No need for DynamoDB table (saves ~$5-10/month)
- Simpler setup with fewer resources
- Same reliability and security

NOTE: Run this setup only once per environment.
