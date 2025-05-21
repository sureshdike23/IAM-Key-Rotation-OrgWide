1. Root Folder

# Org-Wide AWS IAM Access Key Rotation with Secrets Manager & Terraform

## Overview

This repo provides an automated solution to **rotate IAM user access keys across multiple AWS accounts within an AWS Organization**. It uses:

- **AWS Lambda** with Python to rotate keys by assuming roles in member accounts
- **Terraform** to provision necessary IAM roles, Lambda function, Secrets Manager secrets, and SNS alerts
- Rotation includes **automatic deletion of old keys after 8 days**
- Alerts via **SNS email notifications** on success or failure

---

## Repo Structure
IAM-Key-Rotation-OrgWide/
├── README.md
├── central-admin/
│ ├── main.tf
│ ├── variables.tf
│ ├── terraform.tfvars.example
│ ├── outputs.tf
│ ├── lambda/
│ │ ├── rotate_key.py
│ │ └── requirements.txt
│ └── scripts/
│ └── package_lambda.sh
├── member-account/
│ ├── main.tf
│ ├── variables.tf
│ ├── terraform.tfvars.example
│ └── outputs.tf
└── LICENSE


## Prerequisites

- AWS CLI configured with access to management, delegated admin, and member accounts
- Terraform installed (>= 1.0 recommended)
- AWS Organizations set up with delegated admin account registered for Secrets Manager trusted access
- Basic knowledge of AWS IAM, Lambda, and Secrets Manager

---

## Step 1: AWS Organizations Setup (Management Account)

Run these commands in the **Management Account**:

```bash
aws organizations enable-aws-service-access --service-principal secretsmanager.amazonaws.com

aws organizations register-delegated-administrator \
  --account-id <Delegated-Admin-Account-ID> \
  --service-principal secretsmanager.amazonaws.com


##Step 2: Deploy Member Account Module
In each member AWS account, deploy the member-account Terraform module to create the KeyRotatorRole:

Update member-account/terraform.tfvars with:

h
Copy
Edit
lambda_execution_role_arn = "<Lambda execution role ARN from delegated admin account>"
user_name = "<IAM user name to rotate keys for>"
Run Terraform:

bash
Copy
Edit
cd member-account
terraform init
terraform apply


##Step 3: Deploy Central Admin Stack
In the Delegated Admin Account, deploy the central stack:

Update central-admin/terraform.tfvars with:

hcl
Copy
Edit
aws_region = "us-east-1"
rotation_interval_days = 7
alert_email = "your-email@example.com"

accounts_users = {
  "123456789012" = ["user1", "user2"]
  "210987654321" = ["userA"]
}
Run Terraform:

bash
Copy
Edit
cd central-admin
terraform init
terraform apply


##Step 4: Testing Rotation
You can manually invoke the Lambda or rotate secrets:

bash
Copy
Edit
aws lambda invoke --function-name <lambda-name> response.json
Or rotate a specific secret:

bash
Copy
Edit
aws secretsmanager rotate-secret --secret-id <secret-name>
Check:

Secrets Manager for updated secrets

IAM console in member accounts for rotated keys

SNS email alerts for status

Step 5: Ongoing Operations
Rotation runs automatically every rotation_interval_days

Old keys older than 8 days are deleted

Alerts keep you posted on successes/failures


##Troubleshooting & Tips
Make sure cross-account role trusts are correctly configured

Ensure Lambda has permissions to assume member roles

Check CloudWatch logs of Lambda for detailed info

SNS alerts provide quick heads-up on failures

=====================================================================================






