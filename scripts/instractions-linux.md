# README: Setting Up EKS Project on Linux

This document provides instructions on how to use the `setup-eks-project-linux.sh` script to set up an EKS project and use Terraform commands to manage the infrastructure.

---

## Prerequisites

1. **Install Terraform**:
   - Download Terraform from the [official website](https://www.terraform.io/downloads.html).
   - Follow the installation instructions for your Linux distribution.

2. **Install AWS CLI**:
   - Download and install the AWS CLI from the [official website](https://aws.amazon.com/cli/).
   - Configure it using `aws configure` with your AWS credentials.

3. **Set Up SSH Key**:
   - Ensure you have an SSH key pair created and available in your AWS account.
   - Update the `ssh_key_name` variable in the `terraform.tfvars` file with your key name.

4. **Update Script Variables**:
   - Replace `<your-username>` in the `setup-eks-project-linux.sh` script with your Linux username.

---

## How to Run the Script

1. **Make the Script Executable**:
   ```bash
   chmod +x setup-eks-project-linux.sh
   ```

2. **Run the Script**:
   ```bash
   ./setup-eks-project-linux.sh
   ```
   This will create the necessary directory structure and Terraform configuration files for the EKS project.

---

## Using Terraform

### Initialize the Project
Run the following command in the root directory of the project:
```bash
terraform init
```
This command initializes the Terraform working directory and downloads the required provider plugins.

### Validate the Configuration
To ensure the configuration files are correct, run:
```bash
terraform validate
```

### Plan the Infrastructure
Generate an execution plan to preview the changes Terraform will make:
```bash
terraform plan
```

### Apply the Configuration
To create the infrastructure, run:
```bash
terraform apply
```
Terraform will prompt for confirmation before applying the changes.

### Destroy the Infrastructure
To tear down the infrastructure, run:
```bash
terraform destroy
```
Terraform will prompt for confirmation before destroying the resources.

---

## Notes
- Ensure your AWS credentials have sufficient permissions to create the required resources.
- Review the `terraform.tfvars` file to customize the project variables as needed.
- The script assumes the use of the `eu-central-1` region. Update the `aws_region` variable in `terraform.tfvars` if you want to use a different region.

---

## Troubleshooting
- If you encounter permission issues, verify your AWS credentials and IAM policies.
- Check the Terraform documentation for detailed error explanations: [Terraform Docs](https://www.terraform.io/docs/index.html).