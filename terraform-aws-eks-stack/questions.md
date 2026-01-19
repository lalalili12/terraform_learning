# Practice Questions

## VPC, NACL, SG
1. Explain the difference between a public and private subnet.
2. How does a NAT Gateway differ from an Internet Gateway?
3. What is the difference between a NACL and a Security Group? When would you use each?
4. How would you restrict access so that only EKS nodes can reach an RDS instance?
5. What happens if you accidentally associate the wrong route table with a subnet?

## IAM
6. What is the difference between an IAM user, group, and role?
7. Why are IAM roles preferred over long-lived access keys?
8. What is least privilege and how do you apply it in IAM policies?
9. How does an assume role policy differ from a permission policy?
10. How would you allow a Kubernetes service account to access an S3 bucket securely?

## EC2, S3, RDS
11. What factors influence your choice of EC2 instance type?
12. How would you secure an S3 bucket that stores Terraform state?
13. What is an RDS subnet group and why is it required?
14. How do you allow only specific security groups to access an RDS instance?
15. What are the trade-offs between RDS and running your own DB on EC2?

## CloudWatch
16. What’s the difference between CloudWatch metrics and logs?
17. How would you set up an alarm for high CPU on an RDS instance?
18. Where would you look to debug a failing EKS pod from an AWS perspective?
19. How can you control log retention and cost in CloudWatch?

## EKS
20. Explain the difference between the EKS control plane and worker nodes.
21. How does EKS networking work (CNI, pod IPs, node IPs)?
22. What are managed node groups and why use them?
23. How would you expose a service in EKS to the internet?
24. How would you securely connect an EKS app to an RDS database?
25. What is IRSA and why is it better than using node IAM roles for everything?

## Terraform
26. What is Terraform state and why is it important?
27. What are the benefits of using remote state with S3 and DynamoDB?
28. Explain the difference between a resource and a module.
29. How do you structure Terraform for multiple environments (dev/stage/prod)?
30. What happens if someone changes resources manually in AWS outside Terraform? How do you handle drift?
31. What is 	erraform taint and when would you use it?
32. How do you pass sensitive values (like DB passwords) into Terraform safely?
