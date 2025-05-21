variable "aws_region" {
  default = "us-east-1"
}

variable "alert_email" {
  description = "Email address for SNS alerts"
  type        = string
}

variable "rotation_interval_days" {
  description = "Days between automatic rotations"
  type        = number
  default     = 7
}

variable "accounts_users" {
  description = "Map of AWS Account IDs to list of IAM usernames"
  type        = map(list(string))
  default     = {}
}
