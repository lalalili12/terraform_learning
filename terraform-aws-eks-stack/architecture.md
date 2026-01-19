# Architecture Overview

## Physical Architecture (EKS + VPC + RDS + S3 + IAM + CloudWatch)

\\\
┌──────────────────────────────────────────────────────────────────────────────┐
│                                AWS ACCOUNT                                   │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐  │
│  │                                VPC (10.0.0.0/16)                       │  │
│  │                                                                        │  │
│  │  ┌──────────────────────────────┐   ┌──────────────────────────────┐   │  │
│  │  │     Public Subnet A          │   │     Public Subnet B          │   │  │
│  │  │     10.0.1.0/24              │   │     10.0.2.0/24              │   │  │
│  │  │                              │   │                              │   │  │
│  │  │  - NAT Gateway               │   │  - (optional) Bastion Host   │   │  │
│  │  │  - Route to IGW              │   │  - Route to IGW              │   │  │
│  │  └──────────────────────────────┘   └──────────────────────────────┘   │  │
│  │                                                                        │  │
│  │  ┌──────────────────────────────┐   ┌──────────────────────────────┐   │  │
│  │  │     Private Subnet A         │   │     Private Subnet B         │   │  │
│  │  │     10.0.11.0/24             │   │     10.0.12.0/24             │   │  │
│  │  │                              │   │                              │   │  │
│  │  │  - EKS Worker Nodes          │   │  - EKS Worker Nodes          │   │  │
│  │  │  - RDS Instance (Postgres)   │   │  - RDS Standby (if Multi-AZ) │   │  │
│  │  │  - Route to NAT Gateway      │   │  - Route to NAT Gateway      │   │  │
│  │  └──────────────────────────────┘   └──────────────────────────────┘   │  │
│  │                                                                        │  │
│  │  ┌────────────────────────────────────────────────────────────────────┐│  │
│  │  │                         EKS Control Plane                          ││  │
│  │  │                     (AWS-managed, not in your VPC)                 ││  │
│  │  │                                                                    ││  │
│  │  │  - API Server                                                      ││  │
│  │  │  - etcd                                                            ││  │
│  │  │  - Cluster management                                              ││  │
│  │  │  - Communicates with worker nodes via ENIs in private subnets      ││  │
│  │  └────────────────────────────────────────────────────────────────────┘│  │
│  └────────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐  │
│  │                                S3 Buckets                              │  │
│  │  - Terraform state bucket                                              │  │
│  │  - App assets bucket                                                   │  │
│  └────────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐  │
│  │                                IAM Roles                               │  │
│  │  - EKS Cluster Role                                                    │  │
│  │  - EKS Node Role                                                       │  │
│  │  - RDS Monitoring Role (optional)                                      │  │
│  │  - Policies for CloudWatch, ECR, S3                                    │  │
│  └────────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐  │
│  │                               CloudWatch                               │  │
│  │  - Log groups for EKS                                                  │  │
│  │  - Metrics for RDS                                                     │  │
│  │  - Alarms (CPU, storage, etc.)                                         │  │
│  └────────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────────┘
\\\

## Traffic Flow Summary

- Users → Internet → LoadBalancer/Service → EKS Nodes → Pods → RDS
- EKS Nodes → NAT Gateway → Internet (for images/updates)
- Terraform → AWS (via IAM) → State in S3, locks in DynamoDB

- RDS:
  - In private subnets
  - Security group allows only EKS node SG on port 5432

- EKS:
  - Control plane managed by AWS
  - Worker nodes in private subnets
  - Node SG controls access to pods and RDS

- S3:
  - Terraform state bucket (remote backend)
  - App bucket for assets/logs

- CloudWatch:
  - Central place for logs and metrics
  - Alarms for RDS CPU, etc.
