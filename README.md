# DevOps Profile — Production Deployment

A production-ready DevOps portfolio page deployed on AWS using modern DevOps practices including Infrastructure as Code, containerisation, CI/CD automation, and cloud monitoring.

**Live URL:** http://44.201.21.34

---

## Architecture Overview

```
Developer (git push)
        │
        ▼
  GitHub Actions
  ┌─────────────────────────────┐
  │  Build → Test → Deploy      │
  └─────────────────────────────┘
        │                │
        │                ▼
        │         Amazon ECR
        │     (container registry)
        │                │
        │     docker pull on deploy
        ▼                │
  ┌─────────────── AWS VPC (10.0.0.0/16) ───────────────────┐
  │  ┌──────────── Public Subnet (10.0.1.0/24) ───────────┐  │
  │  │                                                      │  │
  │  │   EC2 t3.small (Ubuntu 22.04)                       │  │
  │  │   ┌─────────────────────────────────┐               │  │
  │  │   │  Docker Container               │               │  │
  │  │   │  Nginx:alpine · Port 80         │               │  │
  │  │   │  Profile page                   │               │  │
  │  │   └─────────────────────────────────┘               │  │
  │  │              │                                       │  │
  │  │              ▼                                       │  │
  │  │   CloudWatch (/ec2/html-app)                        │  │
  │  │   CPU alarm > 80% · 7-day retention                 │  │
  │  │                                                      │  │
  │  │   Security Group                                     │  │
  │  │   Inbound: port 80 (HTTP) · port 22 (SSH)           │  │
  │  └──────────────────────────────────────────────────────┘  │
  │                    │                                        │
  │          Internet Gateway                                   │
  └────────────────────────────────────────────────────────────┘
        │
        ▼
     Browser
  http://44.201.21.34
```

---

## Stack

| Layer | Technology |
|---|---|
| Application | Static HTML served by Nginx |
| Containerisation | Docker (nginx:alpine) |
| Container Registry | Amazon ECR |
| Compute | AWS EC2 t3.small (Ubuntu 22.04 LTS) |
| Networking | AWS VPC, Public Subnet, Internet Gateway |
| IaC | Terraform (modular) |
| CI/CD | GitHub Actions |
| Monitoring | AWS CloudWatch |
| IAM | EC2 instance role with ECR + CloudWatch policies |

---

## Repository Structure

```
my-devops-profile/
├── app/
│   └── index.html                  # DevOps profile webpage
├── terraform/
│   ├── main.tf                     # Root — wires all modules
│   ├── variables.tf                # Input variable definitions
│   ├── outputs.tf                  # Output values (IP, URL, ECR)
│   └── modules/
│       ├── vpc/                    # VPC, subnet, IGW, route table
│       ├── ecr/                    # ECR repository + lifecycle policy
│       ├── ec2/                    # EC2 instance, security group, IAM
│       │   └── userdata.sh         # Bootstrap: Docker, AWS CLI, CloudWatch agent
│       └── cloudwatch/             # Log group + CPU alarm
├── .github/
│   └── workflows/
│       └── deploy.yml              # CI/CD pipeline
├── Dockerfile                      # Nginx container definition
└── README.md
```

---

## Deployment Steps

### Prerequisites

- AWS account with programmatic access (Access Key + Secret)
- Terraform >= 1.3.0 installed
- AWS CLI configured (`aws configure`)
- Docker installed
- An EC2 Key Pair created in your AWS account

### 1. Clone the repository

```bash
git clone https://github.com/Adewumicrown/my-devops-profile.git
cd my-devops-profile
```

### 2. Provision infrastructure with Terraform

```bash
cd terraform
terraform init
terraform plan -var="key_name=your-key-pair-name"
terraform apply -var="key_name=your-key-pair-name"
```

Note the outputs — you will need the `ecr_repository_url` and `ec2_public_ip`.

### 3. Build and push Docker image to ECR

```bash
# Authenticate Docker to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <ecr_registry_url>

# Build, tag and push
docker build -t html-app .
docker tag html-app:latest <ecr_repository_url>:latest
docker push <ecr_repository_url>:latest
```

### 4. Deploy container on EC2

```bash
ssh -i ~/.ssh/your-key.pem ubuntu@<ec2_public_ip>

# Inside EC2
aws ecr get-login-password --region us-east-1 | \
  sudo docker login --username AWS --password-stdin <ecr_registry_url>

sudo docker pull <ecr_repository_url>:latest

sudo docker run -d \
  --name devops-profile \
  --restart always \
  -p 80:80 \
  <ecr_repository_url>:latest
```

### 5. CI/CD — automated deployments

After the initial setup, every push to `main` triggers the GitHub Actions pipeline automatically:

1. **Build** — builds the Docker image
2. **Test** — runs the container and verifies the page loads with a `curl` health check
3. **Push** — pushes the image to ECR (tagged as `latest` and by commit SHA)
4. **Deploy** — SSHs into EC2, pulls the new image, restarts the container

### 6. Destroy infrastructure (when done)

```bash
cd terraform
terraform destroy -var="key_name=your-key-pair-name"
```

---

## CI/CD Pipeline

The pipeline is defined in `.github/workflows/deploy.yml` and consists of three sequential jobs:

**Job 1 — Build & Test:** Checks out the code, builds the Docker image locally, runs the container and uses `curl` to verify the profile page loads correctly.

**Job 2 — Push to ECR:** Configures AWS credentials, authenticates Docker to ECR, then builds and pushes the image tagged as both `latest` and the Git commit SHA for traceability.

**Job 3 — Deploy to EC2:** SSHs into the EC2 instance using a stored private key secret, pulls the latest image from ECR, stops and removes the old container, and starts the new one with `--restart always`.

### Required GitHub Secrets

| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | AWS programmatic access key |
| `AWS_SECRET_ACCESS_KEY` | AWS secret access key |
| `EC2_SSH_PRIVATE_KEY` | Contents of your `.pem` key file |

---

## Design Decisions

**Docker on EC2 over ECS Fargate** — ECS Fargate is not covered under AWS free credits, while EC2 t3.small is. The architecture uses Docker directly on EC2 with `--restart always` to ensure the container recovers from reboots. This meets all containerisation requirements without additional cost.

**Modular Terraform** — each concern (VPC, ECR, EC2, CloudWatch) is separated into its own module with its own `main.tf`, `variables.tf`, and `outputs.tf`. This makes each module independently testable, reusable across projects, and easy to understand in isolation.

**GitHub Actions over Jenkins** — GitHub Actions requires no server to manage and integrates natively with the repository. For a project of this scope it is operationally simpler and faster to set up, while still delivering a full build → test → deploy pipeline.

**Nginx:alpine base image** — the profile page is a static HTML file. Nginx on Alpine Linux is the lightest appropriate base image (~23MB), has a minimal attack surface, and serves static content efficiently.

**Single public subnet** — the application is a static profile page with no database or private backend components. A single public subnet is sufficient. A private subnet + NAT gateway would add cost (~$32/month) with no benefit for this use case.

**CloudWatch for monitoring** — CloudWatch integrates natively with EC2 at no additional infrastructure cost. Docker logs are forwarded via the `awslogs` driver directly to the CloudWatch log group. A CPU alarm is configured to alert at 80% sustained usage.

---

## Assumptions

- The application is a static page with no backend or database requirements.
- A single availability zone is acceptable — this is a portfolio project, not a multi-AZ production service.
- SSH access on port 22 is open to `0.0.0.0/0` to allow GitHub Actions to deploy. In a real production environment this would be restricted to known IP ranges or replaced with AWS Systems Manager Session Manager.
- The EC2 instance's public IP is static for the duration of the assessment. An Elastic IP would be required for a permanent deployment.
- AWS credentials used in GitHub Actions have sufficient permissions to push to ECR and describe EC2 instances.

---

## Limitations and Improvements

| Area | Current State | Improvement |
|---|---|---|
| TLS / HTTPS | HTTP only | Add ACM certificate + ALB or Nginx with Let's Encrypt |
| High availability | Single EC2 instance | Auto Scaling Group across multiple AZs |
| Static IP | Dynamic public IP | Assign an Elastic IP |
| Secrets management | GitHub Actions secrets | AWS Secrets Manager or Parameter Store |
| Container orchestration | Docker on EC2 | ECS Fargate or EKS for production scale |
| Alerting | CloudWatch alarm (no action) | Connect alarm to SNS → email/Slack notification |
