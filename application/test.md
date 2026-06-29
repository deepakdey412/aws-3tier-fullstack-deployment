# Production-Ready 3-Tier AWS Application

> **Highly Available · Scalable · Secure**  
> React + Vite · Spring Boot 3 · MySQL on RDS Multi-AZ · Terraform IaC

---

## Project Summary

A complete, production-grade inventory CRUD application deployed on AWS using a classic 3-tier architecture. Every layer lives in its own isolated network tier, communicates only through load balancers, scales automatically, and logs to CloudWatch. Infrastructure is 100% managed by Terraform modules.

---

## Architecture Overview

<!-- Architecture diagram placeholder -->

---

## Deployment Walkthrough

### Step 1 — S3 Backend Created

<img src="output-screenshot/01-s3-backend-created.png" alt="S3 Backend Created" width="100%">

### Step 2 — S3 Backend Configured for Infrastructure

<img src="output-screenshot/02-s3-backend-configure-for-infra.png" alt="S3 Backend Configured for Infra" width="100%">

### Step 3 — Resources Created

<img src="output-screenshot/03-resouces-created.png" alt="Resources Created" width="100%">

---

## AWS Components

### Networking

| Resource            | Details                                   |
| ------------------- | ----------------------------------------- |
| VPC                 | 10.0.0.0/16, DNS enabled                  |
| Public Subnets      | 10.0.1.0/24, 10.0.2.0/24 (AZ-1a, AZ-1b)   |
| Private App Subnets | 10.0.3.0/24, 10.0.4.0/24                  |
| Private DB Subnets  | 10.0.5.0/24, 10.0.6.0/24                  |
| Internet Gateway    | Public traffic ingress                    |
| NAT Gateways        | 2× (one per AZ) for private subnet egress |

### Step 4 — VPC AWS 3-Tier Network

<img src="output-screenshot/04-vpc-aws-3tire.png" alt="VPC AWS 3-Tier" width="100%">

### Step 5 — Six Subnets

<img src="output-screenshot/05-six-subnets.png" alt="Six Subnets" width="100%">

---

### Compute

| Resource         | Details                                     |
| ---------------- | ------------------------------------------- |
| Web ASG          | 1–4 × t3.micro, Ubuntu, Nginx serving React |
| App ASG          | 1–4 × t3.micro, Ubuntu, Spring Boot JAR     |
| Launch Templates | IMDSv2 enforced, EBS encrypted, gp3 volumes |

### Step 6 — Web and App Instances

<img src="output-screenshot/06-web-and-app-instances.png" alt="Web and App Instances" width="100%">

---

### Load Balancers

| ALB     | Type            | Listener             |
| ------- | --------------- | -------------------- |
| Web ALB | Internet-facing | HTTP :80 → Web ASG   |
| App ALB | Internal        | HTTP :8080 → App ASG |

### Step 7 — Web and App Load Balancers

<img src="output-screenshot/07-web-and-app-load-balancers.png" alt="Web and App Load Balancers" width="100%">

### Step 8 — Web and App Target Groups

<img src="output-screenshot/08-web-and-app-target-groups.png" alt="Web and App Target Groups" width="100%">

---

### Database

| Resource      | Details                                   |
| ------------- | ----------------------------------------- |
| RDS MySQL 8.0 | Multi-AZ (Primary + Standby), db.t3.micro |

### Step 9 — RDS Multi-AZ

<img src="output-screenshot/09-rds.png" alt="RDS Multi-AZ" width="100%">

---

### Security Groups — Flow

```
Users → ALB-SG(80/443) → WEB-SG(80/443) → APP-SG(8080) → DB-SG(3306)
```

Each layer accepts traffic **only** from the layer directly above it.

### Supporting Services

| Service       | Purpose                                                         |
| ------------- | --------------------------------------------------------------- |
| S3            | Build artifacts, ALB access logs, app backups                   |
| CloudWatch    | Dashboards, CPU/storage alarms, log groups                      |
| IAM           | EC2 instance profile (SSM + S3 + CW Agent), RDS monitoring role |
| VPC Flow Logs | All traffic logged to CloudWatch Logs                           |
| SNS           | Alarm notifications via email                                   |

---

## Application Stack

| Layer      | Technology                                      |
| ---------- | ----------------------------------------------- |
| Frontend   | React 18 + Vite 5 — Inventory CRUD UI           |
| Web Server | Nginx — serves SPA, proxies `/api/*` to App ALB |
| Backend    | Spring Boot 3.2 / Java 21 — REST CRUD API       |
| ORM        | Spring Data JPA / Hibernate                     |
| Database   | MySQL 8.0 — `items` table                       |

### API Endpoints

```
POST   /api/items          Create item
GET    /api/items          List all items
GET    /api/items/{id}     Get item by ID
PUT    /api/items/{id}     Update item
DELETE /api/items/{id}     Delete item
GET    /api/items/search?q Search by name/description
GET    /api/health         Health check (used by ALB)
GET    /actuator/health    Spring Boot actuator
```

---

## Build & Deploy

### Step 10 — Push App Build to S3 and Refresh

<img src="output-screenshot/10-push-app-build-in-s3-and-refersh.png" alt="Push App Build to S3 and Refresh" width="100%">

### Step 11 — All New Instances Created

<img src="output-screenshot/11-all-new-instances-created.png" alt="All New Instances Created" width="100%">

---

## Application Output

### Step 12 — Application Frontend Live

<img src="output-screenshot/12-application-frontend.png" alt="Application Frontend" width="100%">

### Step 13 — S3 Artifacts

<img src="output-screenshot/13-s3.png" alt="S3 Artifacts" width="100%">

### Step 14 — CloudWatch Monitoring

<img src="output-screenshot/14-cloud-watch.png" alt="CloudWatch Monitoring" width="100%">

---

## Infrastructure Destroyed

### Step 15 — Infra Destroyed

<img src="output-screenshot/15-infra-destoryed.png" alt="Infrastructure Destroyed" width="100%">

---

## Project Structure

```
aws-3tier-app/
├── README.md                    # Project overview and architecture
├── QUICK-START.md              # Complete deployment guide
├── FREE-TIER.txt               # Cost optimization guide
├── application/                # Application code
│   ├── frontend/              # React + Vite frontend
│   └── backend/               # Spring Boot backend
├── terraform/                 # Infrastructure as Code
│   ├── backend-setup/         # S3 backend for Terraform state
│   ├── environments/prod/     # Production environment config
│   └── modules/               # Reusable Terraform modules
├── scripts/                   # Build, deploy, and verification scripts
│   ├── build.sh              # Build frontend and backend
│   ├── deploy.sh             # Deploy to AWS
│   ├── verify.sh             # Verify deployment
│   ├── check-prerequisites.sh # Check required tools
│   └── validate-project.sh   # Validate project structure
└── dist/                      # Build artifacts (generated)
    ├── frontend/             # React production build
    └── backend/              # Spring Boot JAR
```

---

## Getting Started

📖 **Complete deployment guide:** See [QUICK-START.md](QUICK-START.md)

**Quick Overview:**

1. Check prerequisites → `./scripts/check-prerequisites.sh`
2. Setup Terraform backend → `cd terraform/backend-setup && terraform apply`
3. Deploy infrastructure → `cd terraform/environments/prod && terraform apply`
4. Build application → `./scripts/build.sh`
5. Deploy application → `./scripts/deploy.sh`
6. Verify → `./scripts/verify.sh --wait`

**Detailed instructions, AWS console checks, and troubleshooting:** [QUICK-START.md](QUICK-START.md)

---

## Security Best Practices Applied

- IMDSv2 enforced on all EC2 instances
- EBS volumes encrypted at rest
- RDS storage encrypted
- S3 bucket: public access blocked, SSE-AES256, versioning enabled
- Security groups follow least-privilege (no 0.0.0.0/0 on private tiers)
- VPC Flow Logs enabled
- DB subnet has no internet route
- IAM roles use least-privilege policies
- Secrets handled via environment variables on instances (upgrade to Secrets Manager for real production)

---

## Cost Estimate (Free Tier Eligible)

| Resource         | Free Tier              | Notes                                 |
| ---------------- | ---------------------- | ------------------------------------- |
| EC2 t3.micro × 2 | 750 hrs/mo first 12 mo | 4 instances across 2 ASGs             |
| RDS db.t3.micro  | 750 hrs/mo first 12 mo | Multi-AZ doubles cost after free tier |
| S3               | 5 GB free              | Logs and artifacts                    |
| NAT Gateways     | **Not free**           | ~$32/mo per gateway × 2               |
| ALB              | 750 hrs/mo first 12 mo | 2 ALBs                                |

> **Note:** NAT Gateways are the main cost driver (~$64/mo). For dev/test you can reduce to 1 NAT gateway.
