# Quick Start Guide

Complete deployment guide for AWS 3-Tier Application from scratch.

---

## Prerequisites Check

**Run the prerequisite checker first:**
```bash
./scripts/check-prerequisites.sh #bash
```

**Required Tools:**
- **Node.js 18+** - Frontend build
- **Java 21+** - Backend compilation
- **Maven 3.8+** (or use included Maven Wrapper) - Java build tool
- **Terraform 1.5+** - Infrastructure provisioning
- **AWS CLI v2** - AWS resource management
- **Git** - Version control
- **Bash** - Script execution

**Why we need these:**
- **Node.js/npm** → Build React frontend into static files
- **Java/Maven** → Compile Spring Boot application into executable JAR
- **Terraform** → Provision all AWS infrastructure (VPC, EC2, RDS, ALB, etc.)
- **AWS CLI** → Interact with AWS services and verify deployment
- **Git** → Clone repository and manage code versions

---

## Step 1: Setup Terraform Backend (S3 State Storage)

**Why:** Terraform needs a place to store infrastructure state. S3 provides remote, versioned state storage with locking.

```bash
cd terraform/backend-setup

# Edit terraform.tfvars with your settings
# Required: aws_region, project_name

terraform init
terraform apply
# Type: yes 
#Note : this s3 is to store the infrastructure state file , so the state file of this s3 backend will be create and store in your local 
```

**Output:** Note the S3 bucket name (e.g., `aws-3tier-app-tfstate-backend`)

**What this creates:**
- ✅ S3 bucket for Terraform state files
- ✅ Versioning enabled (rollback capability)
- ✅ Encryption enabled (security)
- ✅ S3 native locking (no DynamoDB cost)

---

## Step 2: Configure Main Terraform Backend

**Edit:** `terraform/environments/prod/backend.tf`

**Uncomment and update the backend block:**
```hcl
terraform {
  backend "s3" {
    bucket         = "YOUR-BUCKET-NAME-FROM-STEP-1"
    key            = "prod/terraform.tfstate"
    region         = "ap-south-1"  # Your AWS region
    encrypt        = true
    use_lockfile   = true  # S3 native locking
  }
}
```

---

## Step 3: Configure Environment Variables

**Edit:** `terraform/environments/prod/terraform.tfvars`

**Required settings:**
```hcl
aws_region   = "ap-south-1"              # Your AWS region
project_name = "aws-3tier-app-project"   # Project identifier

# EC2 Settings
key_name = ""  # Leave empty for no SSH, or add your key pair name

# RDS Database (IMPORTANT!)
db_name     = "cruddb"              # Alphanumeric only, no hyphens
db_username = "admin"
db_password = "ChangeMe2026Pass"    # No special chars: / @ " or spaces

# Monitoring
alarm_email = "your-email@example.com"  # CloudWatch alarms
```

**Important Notes:**
- Database name must be alphanumeric only (no `-` or `_`)
- Database password cannot contain: `/`, `@`, `"`, or spaces
- Change the default password for security!

---

## Step 4: Deploy Infrastructure

**Deploy all AWS resources:**
```bash
cd terraform/environments/prod

terraform init -migrate-state  # Migrate state to S3 backend
terraform plan                 # Review what will be created
terraform apply                # Deploy (type: yes)
```

**Time:** ~15-20 minutes

**What this creates:**
- ✅ VPC with 6 subnets across 2 availability zones
- ✅ 2 NAT Gateways (for private subnet internet access)
- ✅ 2 Application Load Balancers (Internet-facing + Internal)
- ✅ 2 Auto Scaling Groups (Web tier + App tier)
- ✅ 4 EC2 instances (2 web + 2 app, t3.micro)
- ✅ RDS MySQL database (Single-AZ, db.t3.micro)
- ✅ S3 bucket for logs and build artifacts
- ✅ Security Groups (layered security)
- ✅ CloudWatch dashboard and alarms
- ✅ IAM roles for EC2 instances

**Check Terraform Outputs:**
```bash
terraform output
```

**Important outputs:**
- `web_alb_dns_name` - Your application URL
- `s3_bucket_name` - Where build artifacts are stored
- `cloudwatch_dashboard_url` - Monitoring dashboard

---

## Step 5: Build Application

**Compile frontend and backend:**
```bash
cd ../../../  # Back to project root
./scripts/build.sh
```

**What this does:**
1. ✅ Builds React frontend using Vite
2. ✅ Creates optimized production bundle
3. ✅ Compiles Spring Boot application to JAR
4. ✅ Saves artifacts to `dist/` folder:
   - `dist/frontend/dist.tar.gz` (React static files)
   - `dist/backend/app.jar` (Spring Boot executable)

**Time:** ~2-3 minutes

**Note:** If Maven is not installed, the script automatically uses the included Maven Wrapper (`./mvnw`)

---

## Step 6: Deploy Application

**Upload artifacts and refresh instances:**
```bash
./scripts/deploy.sh
```

**What this does:**
1. ✅ Uploads `app.jar` to S3
2. ✅ Uploads frontend build to S3
3. ✅ Triggers ASG instance refresh for Web tier
4. ✅ Triggers ASG instance refresh for App tier
5. ✅ Waits for instances to become healthy

**Time:** ~10-15 minutes (instances download from S3 during refresh)

**Instance Refresh Process:**
- Old instances are gracefully terminated
- New instances launch with updated user-data
- New instances download latest artifacts from S3
- Health checks must pass before instance is marked healthy
- Rolling update (50% at a time for zero downtime)

---

## Step 7: Verify Deployment

**Run automated verification:**
```bash
./scripts/verify.sh --wait
```

**This checks:**
- ✅ Web ALB responds (HTTP 200)
- ✅ Backend API health endpoint (HTTP 200)
- ✅ CRUD operations (POST, GET items)
- ✅ Auto Scaling Groups (all instances healthy)
- ✅ S3 build artifacts exist

**Expected output:**
```
╔══════════════════════════════════════════════╗
║   3-Tier AWS App — Verification Report       ║
╚══════════════════════════════════════════════╝

── 1. Web ALB (Internet-Facing) ──────────────
✓  Web ALB responding: HTTP 200

── 2. Backend API (/api/health) ──────────────
✓  API health check: HTTP 200

── 3. CRUD Smoke Test ────────────────────────
✓  POST /api/items → HTTP 201
✓  GET /api/items → HTTP 200

── 4. Auto Scaling Groups ────────────────────
✓  Web ASG: 2 instance(s) InService
✓  App ASG: 2 instance(s) InService

── 5. S3 Build Artifacts ─────────────────────
✓  frontend/dist.tar.gz exists
✓  backend/app.jar exists

══════════════════════════════════════════════
All checks passed! ✓
══════════════════════════════════════════════
```

---

## Step 8: Access Your Application

**Get the application URL:**
```bash
cd terraform/environments/prod
terraform output web_alb_dns_name
```

**Open in browser:**
```
http://aws-3tier-app-project-web-alb-XXXXXXXXXX.ap-south-1.elb.amazonaws.com
```

**Test CRUD Operations:**
1. Create a new item (Name, Description, Quantity)
2. View items in the table
3. Edit an item (click row)
4. Delete an item (Delete button)
5. Search items (search bar)

---

## Step 9: Monitor Your Application

### AWS Console Checks

**EC2 Instances:**
1. Go to: **EC2 → Instances**
2. Verify: 4 instances running (2 web + 2 app)
3. Check: Instance state = "running"

**Target Groups:**
1. Go to: **EC2 → Target Groups**
2. Check: `aws-3tier-app-project-web-tg` (2 healthy targets)
3. Check: `aws-3tier-app-project-app-tg` (2 healthy targets)

**Load Balancers:**
1. Go to: **EC2 → Load Balancers**
2. Check: `aws-3tier-app-project-web-alb` (active)
3. Check: `aws-3tier-app-project-app-alb` (active)

**RDS Database:**
1. Go to: **RDS → Databases**
2. Check: `aws-3tier-app-project-prod-mysql` (available)
3. Verify: Single-AZ deployment

**S3 Bucket:**
1. Go to: **S3 → Buckets**
2. Find: `aws-3tier-app-project-prod-logs-XXXXXXXX`
3. Check folders: `builds/frontend/` and `builds/backend/`

**CloudWatch Dashboard:**
```bash
# Get dashboard URL
terraform output cloudwatch_dashboard_url
```
Or go to: **CloudWatch → Dashboards → aws-3tier-app-project-prod**

**Metrics to monitor:**
- ALB Request Count
- ALB Response Time
- ASG CPU Utilization
- RDS CPU Utilization
- RDS Database Connections
- RDS Free Storage Space

---

## Step 10: Clean Up Resources

**When you're done testing, destroy everything to avoid charges.**

### 10a. Destroy Main Infrastructure

```bash
cd terraform/environments/prod
terraform destroy
# Type: yes
```

**This deletes:**
- ❌ All EC2 instances
- ❌ Load Balancers
- ❌ Auto Scaling Groups
- ❌ RDS database (no final snapshot in free tier)
- ❌ VPC and all networking
- ❌ Security Groups
- ❌ CloudWatch dashboards
- ⚠️ **S3 bucket remains** (safety - contains your state and logs)

**Time:** ~10-15 minutes

### 10b. Clean S3 Bucket

**Must delete S3 contents before destroying bucket:**
```bash
# Get your bucket name
S3_BUCKET=$(terraform output -raw s3_bucket_name 2>/dev/null || echo "aws-3tier-app-project-prod-logs-XXXXXXXX")

# Delete all objects in bucket
aws s3 rm s3://${S3_BUCKET} --recursive

# Verify bucket is empty
aws s3 ls s3://${S3_BUCKET}
```

### 10c. Destroy Terraform Backend (Optional)

**This removes the S3 bucket storing Terraform state:**

```bash
cd ../../backend-setup

# First, delete all objects in state bucket
aws s3 rm s3://aws-3tier-app-tfstate-backend --recursive

# Then destroy the bucket
terraform destroy
# Type: yes
```

**Warning:** This deletes your Terraform state. Only do this if you're completely done with the project.

---

## Troubleshooting

### Issue: Instances not healthy in Target Group

**Check:**
```bash
# Get instance IDs
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names aws-3tier-app-project-web-asg \
  --query 'AutoScalingGroups[0].Instances[*].InstanceId'

# SSH to instance (if key_name was set)
ssh -i ~/.ssh/your-key.pem ubuntu@<instance-public-ip>

# Check logs
sudo cat /var/log/userdata.log
sudo cat /opt/web/logs/nginx-error.log  # Web tier
sudo cat /opt/app/logs/spring.log       # App tier
```

### Issue: Application not loading

**Check:**
1. Web ALB DNS is correct
2. Security group allows port 80 from 0.0.0.0/0
3. Target groups show healthy targets
4. Instances passed health checks (15 minute grace period)

**Verify:**
```bash
./scripts/verify.sh --wait
```

### Issue: Database connection errors

**Check:**
1. RDS security group allows port 3306 from app-sg
2. Database credentials in `terraform.tfvars` are correct
3. Database name has no special characters
4. RDS status is "available"

**Test connection:**
```bash
# From app instance
mysql -h <rds-endpoint> -u admin -p
# Enter password
```

### Issue: Build script fails

**Frontend build fails:**
```bash
cd application/frontend
npm install  # Reinstall dependencies
npm run build
```

**Backend build fails:**
```bash
cd application/backend
./mvnw clean package  # Use Maven Wrapper
# OR
mvn clean package  # If Maven installed
```

### Issue: Terraform destroy hangs on RDS

**Manual RDS deletion:**
```bash
aws rds delete-db-instance \
  --db-instance-identifier aws-3tier-app-project-prod-mysql \
  --skip-final-snapshot \
  --region ap-south-1

# Wait 5-10 minutes, then retry
terraform destroy
```

---

## Cost Optimization Tips

**Free Tier (First 12 months):**
- EC2 t3.micro: 750 hours/month free
- RDS db.t3.micro: 750 hours/month free
- S3: 5 GB storage free
- ALB: 750 hours/month free

**Main Cost: NAT Gateways (~$64/month)**
- NOT free tier eligible
- ~$32/month per gateway × 2

**To reduce costs:**
1. **Stop when not in use:** `terraform destroy` (data persists in S3/RDS snapshots)
2. **Use 1 NAT Gateway:** Edit `vpc` module to use single NAT (saves $32/mo)
3. **Reduce instance count:** Set `min=1, desired=1` in `terraform.tfvars` (not recommended for HA)

**After Free Tier:**
- Monthly cost: ~$150/month
- See `FREE-TIER.txt` for detailed breakdown

---

## Next Steps

**Enhancements:**
- Add SSL/TLS with ACM and Route 53
- Enable Multi-AZ for RDS (high availability)
- Add CloudFront CDN for static assets
- Implement AWS Secrets Manager for credentials
- Set up CI/CD pipeline (GitHub Actions / CodePipeline)
- Add WAF for DDoS protection
- Enable RDS automated backups (after free tier)
- Add ElastiCache for session storage
- Implement auto-scaling based on custom metrics

**Production Readiness:**
- Use private subnets for app tier (remove public IPs)
- Enable AWS Systems Manager Session Manager (no SSH keys)
- Add AWS Config for compliance monitoring
- Implement AWS GuardDuty for threat detection
- Use Parameter Store / Secrets Manager for all secrets
- Enable VPC Flow Logs analysis
- Set up centralized logging with ELK/Splunk
- Implement backup and disaster recovery plan

---

## Summary: Complete Workflow

```bash
# 1. Check prerequisites
./scripts/check-prerequisites.sh

# 2. Setup Terraform backend
cd terraform/backend-setup && terraform init && terraform apply

# 3. Configure backend.tf and terraform.tfvars
# Edit: terraform/environments/prod/backend.tf
# Edit: terraform/environments/prod/terraform.tfvars

# 4. Deploy infrastructure
cd terraform/environments/prod
terraform init -migrate-state
terraform apply

# 5. Build application
cd ../../../
./scripts/build.sh

# 6. Deploy application
./scripts/deploy.sh

# 7. Verify deployment
./scripts/verify.sh --wait

# 8. Get application URL
cd terraform/environments/prod
terraform output web_alb_dns_name

# 9. Monitor in AWS Console
# - EC2 Instances, Target Groups, Load Balancers
# - RDS Database, S3 Bucket, CloudWatch Dashboard

# 10. Clean up (when done)
terraform destroy                              # Destroy infrastructure
aws s3 rm s3://YOUR-BUCKET --recursive        # Clean S3
cd ../../backend-setup && terraform destroy   # Destroy backend
```

**Total Time:** ~45-60 minutes for complete deployment

---

## Support

**Issues or Questions?**
- Check `FREE-TIER.txt` for cost optimization
- Review AWS Console for resource status
- Check CloudWatch Logs for application errors
- Verify security group rules and network connectivity

**Common Commands:**
```bash
# Check infrastructure status
terraform show

# View all outputs
terraform output

# Refresh infrastructure without changes
terraform refresh

# Re-run verification
./scripts/verify.sh

# View CloudWatch logs (Web instances)
aws logs tail /aws/ec2/web-tier --follow

# View CloudWatch logs (App instances)
aws logs tail /aws/ec2/app-tier --follow
```
