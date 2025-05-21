
# IAM Access Key Rotation Org-Wide using AWS Secrets Manager & Terraform

This project automates **IAM access key rotation** for multiple users across **all member accounts in an AWS Organization**, using:

- **AWS Lambda** (centralized function in the Org's admin account)
- **Secrets Manager** (for secure key rotation + scheduling)
- **Cross-account IAM role assumption** (secure access to member accounts)
- **Terraform** (infrastructure-as-code setup)
- **SNS Alerts** (for rotation success, failure, and deletion events)

---

## 📁 Project Structure

```bash
IAM-Key-Rotation-OrgWide/
├── central-admin/
│   ├── lambda/
│   │   └── rotate_key.py         # Lambda function to rotate IAM keys Org-wide
│   ├── scripts/
│   │   └── package_lambda.sh     # Script to zip the Lambda code
│   ├── main.tf                   # Deploys Lambda, IAM roles, and SNS topic
│   ├── variables.tf              # Variables for Terraform
│   ├── terraform.tfvars          # Actual values for variables
│   └── outputs.tf                # Outputs of central Terraform module
├── member-account/
│   ├── main.tf                   # Creates IAM role for Lambda to assume
│   ├── variables.tf              # Variables for member setup
│   └── terraform.tfvars          # Actual values for each member
```

---

## Prerequisites

- An AWS Organization with at least one **management account** and one or more **member accounts**
- CLI access to both
- Terraform installed (`>= 1.0.0`)
- IAM permissions to deploy resources in all involved accounts
- 📨 Email to receive SNS alerts

---

## 🔧 Step-by-Step Setup

### Step 1: Setup in Each **Member Account**

1. **Clone this repo** in your local dev environment.
2. Navigate to `IAM-Key-Rotation-OrgWide/member-account/`
3. Edit `terraform.tfvars` and replace:
   ```hcl
   account_id = "111111111111"          # Replace with the member AWS Account ID
   trusted_account_id = "999999999999"  # Replace with your Org's management account ID
   role_name = "IAMKeyRotationRole"     # Name of the role to create (must match the Lambda's env var)
   ```
4. Deploy the IAM role:
   ```bash
   terraform init
   terraform apply
   ```

Repeat this step for each member account you want to support.

---

### Step 2: Setup in the **Central Org Admin Account**

1. Navigate to `IAM-Key-Rotation-OrgWide/central-admin/`
2. Edit `terraform.tfvars` and update:
   ```hcl
   sns_alert_email = "your@email.com"
   rotation_role_name = "IAMKeyRotationRole"
   accounts_users_json = <<JSON
   {
     "111111111111": ["user1", "user2"],
     "222222222222": ["user3"]
   }
   JSON
   ```
3. Zip the Lambda code:
   ```bash
   cd scripts
   bash package_lambda.sh
   ```
4. Deploy:
   ```bash
   cd ..
   terraform init
   terraform apply
   ```
5. Confirm SNS subscription by verifying the email inbox.

---

## Rotation Process

- Lambda runs and assumes cross-account role in each member account.
- For each user listed, it:
  - Deletes the oldest key (if 2 exist)
  - Creates a new key
  - Sends SNS alert about the key
- Can be triggered manually or via EventBridge

---

## Manual Testing

Run this from the AWS CLI to trigger rotation:
```bash
aws lambda invoke   --function-name <your_lambda_function_name>   --payload '{}'   output.json
```

Then verify:
- ✅ New key exists in IAM
- ✅ Only one active key per user
- ✅ SNS email alert received

---

## 🚀 Automate It

Set up an EventBridge rule to invoke the Lambda function every X days for automatic rotation.

---

## 🛡️ Security Notes

- IAM keys are stored securely in Secrets Manager (optional future enhancement)
- Lambda assumes roles using STS with limited permissions
- Only one key is active per user at any time

---

## 📣 Alerts & Notifications

You’ll receive email alerts for:
- 🔁 Key rotated
- ❌ Failure during rotation
- 🧹 Old key deleted (manual if needed)

---

## 🤝 License

This project is licensed under your own discretion. Use and customize it freely for internal use.

---

## 👋 Questions or Contributions?

Feel free to fork and enhance this repo or open issues for help.
