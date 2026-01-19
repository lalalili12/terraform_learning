# Instructions for Setting Up and Using the Terraform EKS Project

## Prerequisites

1. **Install Terraform**:
   - Download Terraform from the [official website](https://www.terraform.io/downloads).
   - Add Terraform to your system's PATH.

2. **Install AWS CLI**:
   - Download and install the AWS CLI from the [official website](https://aws.amazon.com/cli/).
   - Configure it using `aws configure` with your AWS credentials.

3. **Install PowerShell** (if not already installed):
   - Ensure you have PowerShell installed on your system.

4. **Set Up AWS Resources**:
   - Ensure you have the necessary permissions to create AWS resources (VPC, EKS, RDS, S3, IAM, etc.).

---

## Running the Setup Script

1. **Locate the Script**:
   - The script is located at `scripts/setup-eks-project.ps1`.

2. **Run the Script**:
   - Open PowerShell.
   - Navigate to the directory containing the script.
   - Execute the script using the following command:
     ```powershell
     .\setup-eks-project.ps1
     ```

3. **Verify the Project Structure**:
   - After running the script, the project directory will be created at `C:\Users\ashay\Documents\terraform-aws-eks-stack`.
   - Verify that the directory contains the necessary Terraform files and module folders.

---

## Using Terraform Commands

1. **Navigate to the Project Directory**:
   ```powershell
   cd C:\Users\ashay\Documents\terraform-aws-eks-stack
   ```

2. **Initialize Terraform**:
   - Run the following command to initialize Terraform and download the required providers:
     ```powershell
     terraform init
     ```

3. **Validate the Configuration**:
   - Validate the Terraform configuration files:
     ```powershell
     terraform validate
     ```

4. **Plan the Infrastructure**:
   - Generate an execution plan to see what resources will be created:
     ```powershell
     terraform plan
     ```

5. **Apply the Configuration**:
   - Apply the Terraform configuration to create the infrastructure:
     ```powershell
     terraform apply
     ```
   - Confirm the prompt by typing `yes`.

6. **Check Outputs**:
   - After the apply completes, Terraform will display the outputs (e.g., VPC ID, EKS cluster name, etc.).

7. **Destroy the Infrastructure**:
   - To clean up and destroy all resources created by Terraform:
     ```powershell
     terraform destroy
     ```
   - Confirm the prompt by typing `yes`.

---

## Notes

- **State File**:
  - Terraform state is stored remotely in the S3 bucket `shay-terraform-state-bucket`.
  - Ensure the bucket and DynamoDB table for state locking exist before running the script.

- **Sensitive Variables**:
  - Sensitive variables like `db_password` are defined in `terraform.tfvars`. Do not share this file.

- **Environment-Specific Changes**:
  - Modify `terraform.tfvars` to customize variables like `aws_region`, `project_name`, etc.

- **Debugging**:
  - Use `terraform plan` to debug issues before applying changes.
  - Check AWS CloudWatch logs for troubleshooting EKS and other services.

---

Follow these steps to successfully set up and manage your Terraform EKS project.