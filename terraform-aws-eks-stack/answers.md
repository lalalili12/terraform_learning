# Detailed Answers

## VPC, NACL, SG

1. Difference between public and private subnet  
A public subnet has a route to an Internet Gateway (IGW). Instances can have public IPs and talk directly to the internet.  
A private subnet has no route to IGW. Outbound internet access goes through a NAT Gateway; inbound from the internet is not possible.

2. NAT Gateway vs Internet Gateway  
- NAT Gateway: outbound-only for private subnets, no inbound from internet, used so private instances can reach the internet.  
- Internet Gateway: bidirectional, used by public subnets to allow public access.

3. NACL vs Security Group  
- NACL: stateless, subnet-level, ordered rules, supports allow and deny.  
- Security Group: stateful, instance/ENI-level, allow-only rules, most commonly used for access control.

4. Restrict access so only EKS nodes reach RDS  
Put RDS in private subnets. Create an RDS security group that allows inbound on port 5432 only from the EKS node security group. No public access, no CIDR ranges.

5. Wrong route table associated with subnet  
You can break internet access, accidentally expose private subnets, or isolate resources. EKS nodes may fail to join, RDS may become unreachable, and debugging becomes harder.

## IAM

6. IAM user vs group vs role  
- User: individual identity for a person.  
- Group: collection of users to share policies.  
- Role: identity assumed temporarily by users or services, with its own permissions.

7. Why roles instead of long-lived access keys  
Roles use temporary credentials that rotate automatically, reducing risk. Long-lived keys can leak, be hard to rotate, and violate least privilege.

8. Least privilege  
Grant only the minimum permissions needed to perform a task. For example, give s3:GetObject instead of s3:* if the app only reads objects.

9. Assume role policy vs permission policy  
- Assume role (trust) policy: defines who can assume the role.  
- Permission policy: defines what the role can do once assumed.

10. Allow Kubernetes service account to access S3  
Use IRSA: create an IAM role with trust to the EKS OIDC provider, attach S3 permissions, and annotate the Kubernetes service account with the role ARN so pods get temporary credentials.

## EC2, S3, RDS

11. Choosing EC2 instance type  
Consider CPU, memory, network, storage performance, cost, and workload type (compute-heavy, memory-heavy, GPU, general purpose).

12. Secure S3 bucket for Terraform state  
Block public access, enable encryption, enable versioning, restrict IAM access to Terraform roles only, and use DynamoDB for state locking.

13. What is an RDS subnet group  
A collection of subnets (usually private) in different AZs where RDS is allowed to place DB instances. Required so RDS knows where it can deploy.

14. Allow only specific SGs to access RDS  
In the RDS security group, set inbound rules with source = EKS node SG and port = DB port (e.g., 5432). No CIDR ranges.

15. RDS vs DB on EC2  
RDS: managed backups, patching, Multi-AZ, easier operations but less OS control and usually higher cost.  
EC2 DB: full control, potentially cheaper, but you manage backups, patching, HA, and failover.

## CloudWatch

16. Metrics vs logs  
Metrics are numeric time-series (CPU, latency). Logs are raw text output from applications and systems.

17. Alarm for high RDS CPU  
Create a CloudWatch alarm on the CPUUtilization metric for the RDS instance, with a threshold (e.g., > 80% for several periods) and an action (SNS notification).

18. Debug failing EKS pod from AWS perspective  
Check CloudWatch logs, node health, ENIs and IPs, security groups, VPC CNI plugin, and IAM permissions (especially if using IRSA).

19. Control CloudWatch cost  
Set log retention policies, delete unused log groups, avoid overly verbose logging, and use filters to reduce ingestion.

## EKS

20. Control plane vs worker nodes  
Control plane is AWS-managed (API server, etcd, scheduler). Worker nodes are EC2 instances in your VPC running your pods.

21. EKS networking  
Pods get IPs from the VPC CIDR via the CNI plugin. Nodes have ENIs in subnets. Services use kube-proxy and iptables to route traffic.

22. Managed node groups  
AWS manages lifecycle (provisioning, scaling, patching, draining) of worker nodes. You define instance types and sizes; AWS handles the heavy lifting.

23. Expose service to internet  
Use a Kubernetes Service of type LoadBalancer. AWS creates an external load balancer and routes traffic to your pods.

24. Securely connect EKS app to RDS  
Place RDS in private subnets, restrict RDS SG to EKS node SG, store DB credentials in Kubernetes Secrets, and avoid public access.

25. What is IRSA  
IAM Roles for Service Accounts: maps Kubernetes service accounts to IAM roles so pods get temporary AWS credentials, enabling fine-grained permissions per workload.

## Terraform

26. What is Terraform state  
A file that stores Terraform's view of the current infrastructure. Used to detect changes and plan updates.

27. Benefits of remote state  
Shared across team, supports locking (with DynamoDB), versioned, more secure, and prevents conflicting changes.

28. Resource vs module  
Resource: single infrastructure object (e.g., ws_instance).  
Module: a collection of resources packaged together for reuse.

29. Multi-environment structure  
Use separate directories or workspaces for dev/stage/prod, with shared modules and environment-specific variables.

30. Manual changes outside Terraform  
Terraform detects drift. You can import resources, re-apply Terraform to overwrite manual changes, or manually revert them.

31. terraform taint  
Marks a resource as tainted so Terraform will destroy and recreate it on the next apply. Useful when a resource is broken or misconfigured.

32. Passing sensitive values  
Use sensitive variables, .tfvars files not committed to Git, environment variables, or secret managers. Never hard-code secrets in .tf files.
