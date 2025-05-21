provider "aws" {
  region = var.aws_region
}

resource "aws_iam_role" "rotation_role" {
  name = "IAMKeyRotationRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${var.trusted_account_id}:root"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "rotation_permissions" {
  name = "AllowKeyRotateAccess"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "iam:ListAccessKeys",
          "iam:CreateAccessKey",
          "iam:DeleteAccessKey",
          "iam:UpdateAccessKey"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "attach" {
  name       = "rotate-attach"
  roles      = [aws_iam_role.rotation_role.name]
  policy_arn = aws_iam_policy.rotation_permissions.arn
}
