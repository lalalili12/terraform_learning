# Terraform Learning

This repository is designed to help you learn and practice Terraform, an Infrastructure as Code (IaC) tool.

## Prerequisites

Before you begin, ensure you have the following installed on your system:

1. **Terraform**:
   - Download the Terraform binary from the [official Terraform website](https://www.terraform.io/downloads.html).
   - Follow the installation instructions for your operating system.

   Example for Windows:
   ```powershell
   # Download the binary and add it to your PATH
   $env:Path += ";C:\path\to\terraform"
   ```

   Example for Linux/Mac:
   ```bash
   # Move the binary to a directory in your PATH
   sudo mv terraform /usr/local/bin/

   # Set the PATH environment variable (if not already set)
   export PATH=$PATH:/usr/local/bin
   ```

2. **Text Editor**:
   - Use any text editor or IDE of your choice (e.g., VS Code, Vim, IntelliJ).

3. **AWS CLI**:
   - Install the AWS Command Line Interface (CLI) to interact with AWS services.
   - Follow the installation instructions from the [official AWS CLI documentation](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html).

   Example for Linux/Mac:
   ```bash
   # Install AWS CLI using a package manager
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   ```

   Example for Windows:
   ```powershell
   # Install AWS CLI using the MSI installer
   Start-Process msiexec.exe -Wait -ArgumentList "/I awscliv2.msi /quiet"
   ```
4. **Terraform Backend**:
   - 🗄️ Backend Prerequisites (S3 + DynamoDB via AWS Console)
      This project uses an S3 bucket to store the Terraform state file and a DynamoDB table for state locking.
      These resources must be created manually in the AWS Console before running .

   - 📦 1. Create the S3 Bucket (Terraform State)
      1. 	Sign in to the AWS Console
      2. 	Open S3
      3. 	Select Create bucket
      4. 	Configure the bucket:
         • 	Bucket name: shay-terraform-state-bucket
         • 	AWS Region: eu-central-1
      5. 	Under Bucket Versioning, choose Enable
      6. 	Under Default encryption, ensure encryption is Enabled
      7. 	Leave other settings as default
      8. 	Click Create bucket

   - 🔒 2. Create the DynamoDB Table (State Locking)
      1. 	In the AWS Console, open DynamoDB
      2. 	Select Create table
      3. 	Configure the table:
         • 	Table name: terraform-locks
         • 	Partition key:  LockID(String)
      4. 	For Table settings, choose Default settings
      5. 	Click Create table

## Getting Started

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd terraform_learning
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Format and validate the configuration:
   ```bash
   terraform fmt
   terraform validate
   ```

4. Plan the infrastructure changes:
   ```bash
   terraform plan
   ```

5. Apply the changes to create the infrastructure:
   ```bash
   terraform apply
   ```

6. Destroy the infrastructure when done:
   ```bash
   terraform destroy
   ```

## Notes

- Always review the Terraform plan before applying changes.
- Use version control to manage your Terraform configuration files.

## Environment Variables
   - Set up AWS credentials and region for Terraform to interact with AWS services.

   Example:
   ```bash
   export AWS_ACCESS_KEY_ID="your-access-key-id"
   export AWS_SECRET_ACCESS_KEY="your-secret-access-key"
   export AWS_DEFAULT_REGION="your-default-region"
   ```

Happy learning!