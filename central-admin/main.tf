provider "aws" {
  region = var.aws_region
}

# IAM Role for Lambda execution
resource "aws_iam_role" "lambda_exec" {
  name = "iam-key-rotation-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "lambda_assume_roles" {
  name        = "LambdaAssumeMemberRolesPolicy"
  description = "Allows Lambda to assume KeyRotatorRole in member accounts"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sts:AssumeRole",
        Resource = [for account_id in keys(var.accounts_users) : "arn:aws:iam::${account_id}:role/KeyRotatorRole"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_assume_roles" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_assume_roles.arn
}

# Attach AWSLambdaBasicExecutionRole for CloudWatch logs
resource "aws_iam_role_policy_attachment" "attach_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Package Lambda zip via external script (see scripts/package_lambda.sh)
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/rotate_key.py"
  output_path = "${path.module}/lambda/rotate_key.zip"
}

resource "aws_lambda_function" "rotate_key" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "org-wide-iam-key-rotation"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "rotate_key.lambda_handler"
  runtime          = "python3.9"
  timeout          = 60

  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)
  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.alert_topic.arn
      ACCOUNTS_USERS = jsonencode(var.accounts_users)
    }
  }
}

# Secrets Manager secrets for each user-account combo
# (Will be created manually or via another process)

# SNS Topic and subscription for alerts
resource "aws_sns_topic" "alert_topic" {
  name = "iam-key-rotation-alerts"
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.alert_topic.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
