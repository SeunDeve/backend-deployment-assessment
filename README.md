# MuchTodo — AWS Infrastructure & Deployment

A Terraform-based AWS infrastructure setup for the MuchTodo Golang backend API, built as part of a DevOps engineering assessment at StartupTech.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Usage](#usage)
- [Infrastructure Details](#infrastructure-details)
- [Security](#security)
- [Evidence](#evidence)
- [Outputs](#outputs)
- [Teardown](#teardown)

---

## Overview

This project provisions production-ready AWS infrastructure for the MuchTodo REST API using Terraform. It includes a custom VPC with public and private subnets, an Application Load Balancer, EC2 instances for the Golang backend and MongoDB database, and a Bastion host for secure SSH access. The application is containerised using Docker and pushed to Docker Hub.

---

## Architecture

```
Internet
    │
    ▼
[ALB — Public Subnets (eu-west-3a / eu-west-3b)]
    │
    ▼
[Backend EC2 — Private Subnet]  ──▶  [MongoDB EC2 — Private Subnet]

[Bastion Host — Public Subnet]  ──▶  SSH jump into private instances
```

### AWS Resources Provisioned

- **VPC** — `10.0.0.0/16` with DNS hostnames and DNS support enabled
- **Subnets** — 2 public, 2 private across different availability zones
- **Internet Gateway** — public subnet internet access
- **NAT Gateway** — private subnet outbound access
- **EC2 Instances** — Bastion, Backend, MongoDB (all `t3.micro`, Amazon Linux 2)
- **Application Load Balancer** — public-facing, forwards port 80 → backend port 8080
- **Security Groups** — scoped per service with least-privilege ingress rules
- **Elastic IP** — assigned to the Bastion host

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Terraform | >= 1.0 | [terraform.io](https://developer.hashicorp.com/terraform/install) |
| AWS CLI | >= 2.0 | [aws.amazon.com/cli](https://aws.amazon.com/cli/) |
| Docker | >= 24.0 | [docs.docker.com](https://docs.docker.com/get-docker/) |
| Git | any | [git-scm.com](https://git-scm.com/) |

You will also need:

- An AWS account with IAM permissions to create VPCs, EC2s, ALBs, and security groups
- An EC2 key pair created in your target AWS region
- Your current public IP address (`curl ifconfig.me`)
- A Docker Hub account for pushing the container image

---

## Project Structure

```
.
├── terraform/
│   ├── main.tf                   # All AWS resource definitions
│   ├── variable.tf               # Input variable declarations
│   ├── output.tf                 # Output values after apply
│   ├── terraform.tf.vars.example # Example variable values
│   ├── backend_setup.sh          # Backend server setup script
│   ├── mongodb_setup.sh          # MongoDB server setup script
│   ├── evidence/                 # Screenshots and deployment proof
│   └── user_data/                # EC2 user data scripts
├── dockerfile                    # Multi-stage Docker build for Golang API
├── .dockerignore                 # Files excluded from Docker build context
├── .gitignore                    # Files excluded from version control
└── README.md
```

---

## Usage

### 1. Clone the repository

```bash
git clone https://github.com/SeunDeve/backend-deployment-assessment.git
cd backend-deployment-assessment
```

### 2. Configure your variables

```bash
cd terraform
cp terraform.tf.vars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
aws_region    = "eu-west-3"
project_name  = "techstartup"
my_ip         = "YOUR_IP/32"    # curl ifconfig.me
```

### 3. Initialise Terraform

```bash
terraform init
```

### 4. Preview the plan

```bash
terraform plan
```

### 5. Apply the infrastructure

```bash
terraform apply
```

Type `yes` when prompted. Provisioning takes approximately 3–5 minutes.

### 6. Build and push the Docker image

```bash
cd ..
docker build -t your-dockerhub-username/much-to-do:latest .
docker push your-dockerhub-username/much-to-do:latest
```

---

## Infrastructure Details

### Networking

| Resource | Value |
|----------|-------|
| VPC CIDR | `10.0.0.0/16` |
| Public Subnet 1 | `10.0.1.0/24` — eu-west-3a |
| Public Subnet 2 | `10.0.2.0/24` — eu-west-3b |
| Private Subnet 1 | `10.0.3.0/24` — eu-west-3a |
| Private Subnet 2 | `10.0.4.0/24` — eu-west-3b |

### Security Group Rules

| Security Group | Port | Source |
|----------------|------|--------|
| ALB SG | 80, 443 | `0.0.0.0/0` |
| Bastion SG | 22 | Your IP only |
| Backend SG | 8080 | ALB SG |
| Backend SG | 22 | Bastion SG |
| MongoDB SG | 27017 | Backend SG |

### EC2 Instances

| Instance | Subnet | AMI | Role |
|----------|--------|-----|------|
| techstartup-bastion | Public (eu-west-3a) | Amazon Linux 2 | SSH jump host |
| techstartup-backend | Private (eu-west-3a) | Amazon Linux 2 | Golang API + Docker |
| techstartup-mongodb | Private (eu-west-3b) | Amazon Linux 2 | MongoDB database |

---

## Security

- The Bastion host is the **only** SSH entry point — backend and MongoDB have no public IPs
- SSH to Bastion is restricted to your IP via `my_ip` variable
- All inter-service traffic uses security group references, not open CIDR blocks
- State files (`*.tfstate`) and key files (`*.pem`) are excluded from version control via `.gitignore`

> Never commit `terraform.tfvars`, `*.tfstate`, or `*.pem` files to Git.

---

## Evidence

### 1. Terraform init

Successfully initialised with AWS provider `v5.100.0`, TLS `v4.3.0`, and local `v2.9.0`.

![Terraform Init](evidence/Terraform_init_.png)

---

### 2. Terraform plan

Plan output showing **29 resources to add**, with all expected outputs listed including ALB DNS name, Bastion public IP, backend and MongoDB private IPs.

![Terraform Plan](evidence/Terraform_Plan.png)

---

### 3. Terraform apply

All **27 resources created successfully** in the `eu-west-3` region. Outputs confirmed:

- `alb_dns_name` = `techstartup-alb-640580184.eu-west-3.elb.amazonaws.com`
- `backend_private_ip` = `10.0.11.224`
- `bastion_public_ip` = `15.236.138.15`
- `mongodb_private_ip` = `10.0.12.81`
- `vpc_id` = `vpc-000b69bf526e0f10e`

![Terraform Apply](evidence/Terraform_Apply.png)

---

### 4. EC2 instances running in AWS Console

All 3 EC2 instances provisioned and passing health checks in the `eu-west-3` (Paris) region.

![EC2 Instances in AWS Console](evidence/VPC_in_AWS_console.png)

---

### 5. MongoDB running on the MongoDB server

SSH into the MongoDB instance via the Bastion host. `systemctl status mongod` confirms MongoDB is **active and running** since `2026-06-24 14:58:53 UTC`.

![MongoDB Running](evidence/Screenshot_2026-06-24_at_4_15_53_PM.png)

---

### 6. SSH from Bastion into Backend server

Successfully SSH-tunnelled from the Bastion host (`15.236.138.15`) into the backend private instance (`10.0.11.224`) using the key pair.

![SSH via Bastion](evidence/Screenshot_2026-06-24_at_4_16_24_PM.png)

---

### 7. Docker image build and push

Multi-stage Docker build completed for the MuchTodo Golang API. Image pushed to Docker Hub as `shay30/much-to-do:latest`.

![Docker Build and Push](evidence/Docker_Build.png)

---

## Outputs

After `terraform apply`, the following values are printed:

| Output | Description | Value |
|--------|-------------|-------|
| `vpc_id` | ID of the provisioned VPC | `vpc-000b69bf526e0f10e` |
| `alb_dns_name` | Public DNS to reach the API | `techstartup-alb-640580184.eu-west-3.elb.amazonaws.com` |
| `bastion_public_ip` | Elastic IP of the Bastion host | `15.236.138.15` |
| `backend_private_ip` | Private IP of the backend server | `10.0.11.224` |
| `mongodb_private_ip` | Private IP of the MongoDB server | `10.0.12.81` |

Test the API via the ALB:

```bash
curl http://techstartup-alb-640580184.eu-west-3.elb.amazonaws.com/health
```

SSH into the backend via the Bastion:

```bash
ssh -A -i newly.pem ec2-user@15.236.138.15        # into Bastion
ssh ec2-user@10.0.11.224                           # from Bastion into Backend
```

---

## Teardown

To destroy all provisioned resources and avoid ongoing AWS charges:

```bash
cd terraform
terraform destroy
```

> The NAT Gateway costs ~$0.045/hr even when idle. Always destroy when not in use.

---

## Author

**Oluwaseun** — DevOps Engineering Assessment, Techstartup  
GitHub: [SeunDeve](https://github.com/SeunDeve)
